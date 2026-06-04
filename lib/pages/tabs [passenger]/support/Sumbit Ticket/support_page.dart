import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/support_service.dart';
import 'support_widgets.dart';

class SubmitTicketPage extends StatefulWidget {
  const SubmitTicketPage({super.key});

  @override
  State<SubmitTicketPage> createState() => _SubmitTicketPageState();
}

class _SubmitTicketPageState extends State<SubmitTicketPage> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategoryKey = 'cat_ride_issue';
  bool _isSubmitting = false;
  final _supportService = SupportService();

  static const _categoryKeys = [
    'cat_ride_issue',
    'cat_payment',
    'cat_driver_complaint',
    'cat_app_bug',
    'cat_other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _supportService.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final category = SupportTicketCategory.fromKey(_selectedCategoryKey);
      await _supportService.createTicket(
        subject: subject,
        description: description,
        category: category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit ticket: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.text(context),
                        size: 22,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.translate('support_ticket'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Main content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      t.translate('submit_a_ticket'),
                      style: AppTextStyles.sectionLabel(
                        context,
                      ).copyWith(color: AppColors.primaryPurple),
                    ),
                    const SizedBox(height: 20),

                    // Subject
                    Text(
                      t.translate('subject'),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: 8),
                    TicketFormField(
                      controller: _subjectController,
                      hintText: t.translate('subject_hint'),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Text(
                      t.translate('category'),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: 8),
                    TicketCategorySelector(
                      value: _selectedCategoryKey,
                      onChanged: (val) =>
                          setState(() => _selectedCategoryKey = val),
                      items: _categoryKeys,
                      labelBuilder: (key) => t.translate(key),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      t.translate('description'),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: 8),
                    TicketFormField(
                      controller: _descriptionController,
                      hintText: t.translate('description_hint'),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 36),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                t.translate('submit_ticket_btn'),
                                style: AppTextStyles.bodyMedium(context)
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
