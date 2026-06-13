import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import '../../../../routing/router.dart';
import 'widgets/complete_profile_top_bar.dart';
import 'widgets/complete_profile_name_fields.dart';
import 'widgets/complete_profile_email_field.dart';
import 'widgets/complete_profile_phone_field.dart';
import 'widgets/complete_profile_error_banner.dart';
import 'widgets/complete_profile_save_button.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  bool _isLoading = false;
  String? _errorMessage;

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _phoneController     = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus  = FocusNode();
  final _emailFocus     = FocusNode();
  final _phoneFocus     = FocusNode();

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _emailController.text     = args['email']     ?? '';
        _firstNameController.text = args['firstName'] ?? '';
        _lastNameController.text  = args['lastName']  ?? '';
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final t         = AppLocalizations.of(context);
    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final phone     = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorMessage = t.translate('error_fill_name'));
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = t.translate('error_phone_required'));
      return;
    }
    if (phone.length != 8 || !RegExp(r'^\d{8}$').hasMatch(phone)) {
      setState(() => _errorMessage = t.translate('error_phone_invalid'));
      return;
    }

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      await _authService.updateProfile(
        firstName: firstName,
        lastName:  lastName,
        phone:     '+216$phone',
      );
      if (mounted) AppRouter.clearAndGo(context, AppRouter.home);
    } catch (e) {
      setState(() =>
          _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            CompleteProfileTopBar(t: t),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    const SizedBox(height: 32),

                    CompleteProfileNameFields(
                      t:                   t,
                      firstNameController: _firstNameController,
                      lastNameController:  _lastNameController,
                      firstNameFocus:      _firstNameFocus,
                      lastNameFocus:       _lastNameFocus,
                      onChanged:           () => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    CompleteProfileEmailField(
                      t:               t,
                      emailController: _emailController,
                      emailFocus:      _emailFocus,
                      onTap:           () => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    CompleteProfilePhoneField(
                      t:               t,
                      phoneController: _phoneController,
                      phoneFocus:      _phoneFocus,
                      onTap:           () => setState(() {}),
                    ),

                    const SizedBox(height: 28),

                    if (_errorMessage != null)
                      CompleteProfileErrorBanner(message: _errorMessage!),

                    CompleteProfileSaveButton(
                      t:         t,
                      isLoading: _isLoading,
                      onPressed: _handleSave,
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