import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import 'support_widgets.dart';

class SubmitTicketPage extends StatefulWidget {
  const SubmitTicketPage({super.key});

  @override
  State<SubmitTicketPage> createState() => _SubmitTicketPageState();
}

class _SubmitTicketPageState extends State<SubmitTicketPage> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Ride Issue';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // Handle ticket submission
  }

  void _handleAttachFiles() {
    // Handle file attachment
    debugPrint('Attach files tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
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
                      'Support Ticket',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'SUBMIT A TICKET',
                      style: AppTextStyles.sectionLabel(context)
                          .copyWith(color: AppColors.primaryPurple),
                    ),
                    const SizedBox(height: 20),

                    // Subject
                    Text('Subject', style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: 8),
                    TicketFormField(
                      controller: _subjectController,
                      hintText: 'Brief summary of the issue',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Text('Category', style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: 8),
                    TicketCategoryDropdown(
                      value: _selectedCategory,
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val ?? _selectedCategory),
                      items: const [
                        'Ride Issue',
                        'Payment',
                        'Driver Complaint',
                        'App Bug',
                        'Other',
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text('Description', style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: 8),
                    TicketFormField(
                      controller: _descriptionController,
                      hintText: 'Provide details about your request...',
                      maxLines: 6,
                    ),
                    const SizedBox(height: 20),

                    // Attach Files - New Design
                    Text('Attach Files', style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _handleAttachFiles,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border(context),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              color: AppColors.primaryPurple,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Add screenshots or receipts',
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  color: AppColors.subtext(context),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primaryPurple,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Submit Button - No Icon
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Ticket',
                          style: AppTextStyles.bodyMedium(context).copyWith(
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