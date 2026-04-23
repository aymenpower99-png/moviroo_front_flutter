import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import 'personal_data_actions.dart';
import 'personal_data_widgets.dart';

// ─── Hub Page ─────────────────────────────────────────────────────────────────

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _authService = AuthService();
  bool _isLoading = true;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = ''; // digits only, without +216 prefix

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser(forceRefresh: true);
      if (!mounted) return;
      if (user != null) {
        final rawPhone = (user['phone'] as String?) ?? '';
        setState(() {
          _firstName = (user['firstName'] as String?) ?? '';
          _lastName = (user['lastName'] as String?) ?? '';
          _email = (user['email'] as String?) ?? '';
          _phone = rawPhone.startsWith('+216') ? rawPhone.substring(4) : rawPhone;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String get _displayName {
    final n = '${_firstName.trim()} ${_lastName.trim()}'.trim();
    return n.isEmpty ? '—' : n;
  }

  Future<void> _open(Widget page) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (updated == true && mounted) _loadUser();
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: AvatarSection(
                              letter: _firstName.isNotEmpty
                                  ? _firstName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(height: 32),
                          SectionLabel(t('personal_details')),
                          const SizedBox(height: 12),
                          // Tappable rows card
                          Material(
                            color: AppColors.surface(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.border(context)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: t('name'),
                                  value: _displayName,
                                  onTap: () => _open(_EditNamePage(
                                    firstName: _firstName,
                                    lastName: _lastName,
                                  )),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.border(context),
                                  indent: 16,
                                ),
                                _InfoRow(
                                  label: t('email_address'),
                                  value: _email.isEmpty ? '—' : _email,
                                  onTap: () => _open(_EditEmailPage(email: _email)),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.border(context),
                                  indent: 16,
                                ),
                                _InfoRow(
                                  label: t('phone_number'),
                                  value: _phone.isEmpty ? '—' : '+216 $_phone',
                                  onTap: () => _open(_EditPhonePage(phone: _phone)),
                                ),
                              ],
                            ),
                          ),
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

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium(context)
                        .copyWith(color: AppColors.subtext(context)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primaryPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(context)
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Name Page ───────────────────────────────────────────────────────────

class _EditNamePage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const _EditNamePage({required this.firstName, required this.lastName});

  @override
  State<_EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<_EditNamePage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController(text: widget.firstName);
    _last = TextEditingController(text: widget.lastName);
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _first.text.trim() != widget.firstName ||
      _last.text.trim() != widget.lastName;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _authService.updateProfile(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
      );
      if (!mounted) return;
      _showToast(
        context,
        AppLocalizations.of(context).translate('profile_updated'),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
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
              child: PersonalDataTopBar(
                title: t('edit_name'),
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: Form(
                  key: _formKey,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([_first, _last]),
                    builder: (context, _) => Column(
                      children: [
                        FieldCard(
                          children: [
                            FieldTile(
                              label: t('first_name'),
                              controller: _first,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? t('first_name_required')
                                      : null,
                            ),
                            FieldTile(
                              label: t('last_name'),
                              controller: _last,
                              showBottomBorder: false,
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 32),
                        SaveButton(
                          isSaving: _isSaving,
                          hasChanges: _hasChanges,
                          onPressed: _save,
                        ),
                      ],
                    ),
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

// ─── Edit Email Page ──────────────────────────────────────────────────────────

class _EditEmailPage extends StatefulWidget {
  final String email;
  const _EditEmailPage({required this.email});

  @override
  State<_EditEmailPage> createState() => _EditEmailPageState();
}

class _EditEmailPageState extends State<_EditEmailPage> {
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
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
              child: PersonalDataTopBar(
                title: t('email_address'),
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: Column(
                  children: [
                    FieldCard(
                      children: [
                        FieldTile(
                          label: t('email_address'),
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          showBottomBorder: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primaryPurple,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t('email_cannot_change'),
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.primaryPurple,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ─── Edit Phone Page ──────────────────────────────────────────────────────────

class _EditPhonePage extends StatefulWidget {
  final String phone;
  const _EditPhonePage({required this.phone});

  @override
  State<_EditPhonePage> createState() => _EditPhonePageState();
}

class _EditPhonePageState extends State<_EditPhonePage> {
  final _authService = AuthService();
  late final TextEditingController _phone;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _hasChanges => _phone.text.trim() != widget.phone;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _authService.updateProfile(
        phone: '+216${_phone.text.trim()}',
      );
      if (!mounted) return;
      _showToast(
        context,
        AppLocalizations.of(context).translate('profile_updated'),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
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
              child: PersonalDataTopBar(
                title: t('phone_number'),
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: ListenableBuilder(
                  listenable: _phone,
                  builder: (context, _) => Column(
                    children: [
                      FieldCard(
                        children: [
                          PhoneFieldTile(
                            label: t('phone_number'),
                            controller: _phone,
                            showBottomBorder: false,
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 32),
                      SaveButton(
                        isSaving: _isSaving,
                        hasChanges: _hasChanges,
                        onPressed: _save,
                      ),
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
