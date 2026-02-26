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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_left,
              color: AppColors.text(context),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Support Ticket', style: AppTextStyles.pageTitle(context)),
        centerTitle: true,
        actions: [
      
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

            // Attach Files
            Text('Attach Files', style: AppTextStyles.bodyMedium(context)),
            const SizedBox(height: 8),
            const TicketAttachFiles(),
            const SizedBox(height: 36),

            // Submit
            TicketSubmitButton(onPressed: _onSubmit),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}