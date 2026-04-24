import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

TimeOfDay defaultTimeForDate(DateTime date) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  final base = isToday ? now.add(const Duration(hours: 2)) : now;
  final roundedMinute = ((base.minute / 15).ceil() * 15) % 60;
  final extraHour = (base.minute >= 45) ? 1 : 0;
  return TimeOfDay(hour: (base.hour + extraHour) % 24, minute: roundedMinute);
}

String formatDate(DateTime date, AppLocalizations t) {
  final days = [
    t.translate('day_mon'),
    t.translate('day_tue'),
    t.translate('day_wed'),
    t.translate('day_thu'),
    t.translate('day_fri'),
    t.translate('day_sat'),
    t.translate('day_sun'),
  ];
  final months = [
    t.translate('month_jan'),
    t.translate('month_feb'),
    t.translate('month_mar'),
    t.translate('month_apr'),
    t.translate('month_may'),
    t.translate('month_jun'),
    t.translate('month_jul'),
    t.translate('month_aug'),
    t.translate('month_sep'),
    t.translate('month_oct'),
    t.translate('month_nov'),
    t.translate('month_dec'),
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

String formatTimeLabel(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
