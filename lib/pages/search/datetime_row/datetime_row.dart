import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets.dart';
import 'utils.dart';

class DateTimeRow extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime)? onDateChanged;
  final void Function(TimeOfDay)? onTimeChanged;

  const DateTimeRow({
    super.key,
    this.initialDate,
    this.onDateChanged,
    this.onTimeChanged,
  });

  @override
  State<DateTimeRow> createState() => _DateTimeRowState();
}

class _DateTimeRowState extends State<DateTimeRow> {
  late DateTime _pickedDate;
  late TimeOfDay _pickedTime;

  @override
  void initState() {
    super.initState();
    _pickedDate = widget.initialDate ?? DateTime.now();
    _pickedTime = defaultTimeForDate(_pickedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTimeChanged?.call(_pickedTime);
    });
  }

  String _dateLabel(AppLocalizations t) => formatDate(_pickedDate, t);

  String get _timeLabel => formatTimeLabel(_pickedTime);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: AppColors.primaryPurple,
                  onPrimary: Colors.white,
                  surface: AppColors.surface(context),
                  onSurface: AppColors.text(context),
                )
              : ColorScheme.light(
                  primary: AppColors.primaryPurple,
                  onPrimary: Colors.white,
                  onSurface: AppColors.text(context),
                ),
          dialogBackgroundColor: AppColors.surface(context),
          textTheme: Theme.of(context).textTheme.copyWith(
                headlineMedium: const TextStyle(
                  fontSize: 0,
                  color: Colors.transparent,
                ),
                labelSmall: const TextStyle(
                  fontSize: 0,
                  color: Colors.transparent,
                ),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final newDefault = defaultTimeForDate(picked);
      setState(() {
        _pickedDate = picked;
        _pickedTime = newDefault;
      });
      widget.onDateChanged?.call(picked);
      widget.onTimeChanged?.call(newDefault);
    }
  }

  Future<void> _pickTime() async {
    final t = AppLocalizations.of(context);
    final minuteSlots = [0, 15, 30, 45];
    int initMinuteIndex =
        minuteSlots.indexWhere((m) => m == _pickedTime.minute);
    if (initMinuteIndex < 0) initMinuteIndex = 0;

    int tempHour = _pickedTime.hour;
    int tempMinuteIndex = initMinuteIndex;

    final hourCtrl = FixedExtentScrollController(initialItem: tempHour);
    final minuteCtrl =
        FixedExtentScrollController(initialItem: initMinuteIndex);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setBS) {
            return SizedBox(
              height: 340,
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Text(
                            t.translate('cancel'),
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.subtext(context),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          t.translate('time'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            final picked = TimeOfDay(
                              hour: tempHour,
                              minute: minuteSlots[tempMinuteIndex],
                            );
                            setState(() => _pickedTime = picked);
                            widget.onTimeChanged?.call(picked);
                          },
                          child: Text(
                            t.translate('done'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Drum-roll pickers
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryPurple.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ListWheelScrollView.useDelegate(
                                controller: hourCtrl,
                                itemExtent: 48,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (i) => tempHour = i,
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (_, i) => Center(
                                    child: Text(
                                      i.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              ':',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text(context),
                              ),
                            ),
                            Expanded(
                              child: ListWheelScrollView.useDelegate(
                                controller: minuteCtrl,
                                itemExtent: 48,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (i) =>
                                    tempMinuteIndex = i,
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 4,
                                  builder: (_, i) => Center(
                                    child: Text(
                                      minuteSlots[i]
                                          .toString()
                                          .padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    hourCtrl.dispose();
    minuteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: PillChip(
            icon: Icons.calendar_today_rounded,
            label: _dateLabel(t),
            showChevron: true,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PillChip(
            icon: Icons.access_time_rounded,
            label: _timeLabel,
            showChevron: true,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }
}
