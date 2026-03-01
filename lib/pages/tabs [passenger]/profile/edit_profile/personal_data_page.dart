import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'personal_data_controller.dart';
import 'personal_data_widgets.dart';
import 'personal_data_actions.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _ctrl = PersonalDataController();

  @override
  void initState() {
    super.initState();
    _ctrl.init(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {});
    final success = await _ctrl.save();
    if (!mounted) return;
    final t = AppLocalizations.of(context).translate;
    setState(() {});
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                t('profile_updated'),
                style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: PersonalDataTopBar(onBack: () => Navigator.maybePop(context)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Form(
                  key: _ctrl.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: AvatarSection()),
                      const SizedBox(height: 32),

                      SectionLabel(t('personal_details')),
                      const SizedBox(height: 12),
                      FieldCard(
                        children: [
                          FieldTile(
                            label: t('first_name'),
                            controller: _ctrl.firstName,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? t('first_name_required')
                                : null,
                          ),
                          FieldTile(
                            label: t('last_name'),
                            controller: _ctrl.lastName,
                          ),
                          FieldTile(
                            label: t('email_address'),
                            controller: _ctrl.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return t('email_required');
                              if (!RegExp(r'^[\w.]+@[\w]+\.[a-z]+$').hasMatch(v.trim())) {
                                return t('email_invalid');
                              }
                              return null;
                            },
                          ),
                          FieldTile(
                            label: t('phone_number'),
                            controller: _ctrl.phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      SaveButton(
                        isSaving: _ctrl.isSaving,
                        hasChanges: _ctrl.hasChanges,
                        onPressed: _save,
                      ),

                      const SizedBox(height: 24),
                      const DangerSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}