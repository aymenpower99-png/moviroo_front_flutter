import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import '../../../../routing/router.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  bool _isLoading = false;
  String? _errorMessage;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _emailController.text = args['email'] ?? '';
        _firstNameController.text = args['firstName'] ?? '';
        _lastNameController.text = args['lastName'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorMessage = 'Please fill in your name');
      return;
    }

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Phone number is required');
      return;
    }

    // Validate Tunisia phone: 8 digits
    if (phone.length != 8 || !RegExp(r'^\d{8}$').hasMatch(phone)) {
      setState(() => _errorMessage = 'Enter a valid 8-digit Tunisian number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: '+216$phone',
      );
      if (mounted) {
        AppRouter.clearAndGo(context, AppRouter.home);
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required IconData prefixIcon,
    bool readOnly = false,
    Widget? prefix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium(
        context,
      ).copyWith(color: AppColors.subtext(context)),
      prefixIcon:
          prefix ?? Icon(prefixIcon, color: AppColors.text(context), size: 20),
      filled: true,
      fillColor: readOnly
          ? (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F4))
          : AppColors.surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: isDark
            ? BorderSide.none
            : BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: isDark
            ? BorderSide.none
            : BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.bg(context) : const Color(0xFFD1D5DB),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _label(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: AppTextStyles.sectionLabel(context)),
  );

  Widget _buildTopBar(BuildContext context, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => AppRouter.clearAndGo(context, AppRouter.login),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.text(context),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              t.translate('complete_profile'),
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionLabel(
                context,
              ).copyWith(color: AppColors.text(context)),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildNameFields(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        // ── First Name ────────────────────────────────
        _label(context, t.translate('first_name')),
        const SizedBox(height: 8),
        TextField(
          controller: _firstNameController,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.bodyMedium(context),
          decoration: _fieldDecoration(
            context,
            hint: t.translate('first_name'),
            prefixIcon: Icons.person_outline,
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // ── Last Name ─────────────────────────────────
        _label(context, t.translate('last_name')),
        const SizedBox(height: 8),
        TextField(
          controller: _lastNameController,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.bodyMedium(context),
          decoration: _fieldDecoration(
            context,
            hint: t.translate('last_name'),
            prefixIcon: Icons.person_outline,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, t),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    const SizedBox(height: 32),

                    _buildNameFields(context, t),

                    const SizedBox(height: 16),
                    _label(context, t.translate('label_email_address')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      cursorColor: AppColors.subtext(context),
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.subtext(context)),
                      decoration: _fieldDecoration(
                        context,
                        hint: t.translate('hint_email'),
                        prefixIcon: Icons.email_outlined,
                        readOnly: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Phone Number (Tunisia only) ───────────────
                    _label(context, t.translate('phone_number')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      cursorColor: AppColors.subtext(context),
                      style: AppTextStyles.bodyMedium(context),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: _fieldDecoration(
                        context,
                        hint: '12 345 678',
                        prefixIcon: Icons.phone_outlined,
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  'images/flags/tunisia.png',
                                  width: 24,
                                  height: 16,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+216',
                                style: AppTextStyles.bodyMedium(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppColors.border(context),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Error Message ──────────────────────────────
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Save Button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                t.translate('save_continue'),
                                style: AppTextStyles.buttonPrimary,
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
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
