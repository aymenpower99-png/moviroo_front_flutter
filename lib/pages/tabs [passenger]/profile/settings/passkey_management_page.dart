import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth/webauthn_service.dart';
import '../../../../services/auth/webauthn_platform_channel.dart';
import '../../../../services/auth/auth_helpers.dart';
import '../../../../services/auth_service/auth_service.dart';

class PasskeyManagementPage extends StatefulWidget {
  const PasskeyManagementPage({super.key});

  @override
  State<PasskeyManagementPage> createState() => _PasskeyManagementPageState();
}

class _PasskeyManagementPageState extends State<PasskeyManagementPage> {
  final _webauthn = WebAuthnService();
  List<dynamic> _passkeys = [];
  bool _isBootstrapping = false;
  bool _isBusy = false;
  String? _error;

  String _t(String key) => AppLocalizations.of(context).translate(key);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. Try to populate synchronously from service cache so the first frame
    //    shows data instead of a spinner.
    final token = await AuthService().getAccessToken();
    final userId = token != null ? AuthHelpers.extractUserId(token) : null;
    if (WebAuthnService.hasCacheFor(userId)) {
      final cached = await _webauthn.getPasskeys(); // instant — from cache
      if (mounted) {
        setState(() => _passkeys = cached);
      }
    } else {
      // No cache yet — show spinner on first frame
      setState(() => _isBootstrapping = true);
    }

    // 2. Always refresh in background
    _loadPasskeys();
  }

  Future<void> _loadPasskeys() async {
    try {
      final passkeys = await _webauthn.getPasskeys();
      if (mounted) {
        setState(() {
          _passkeys = passkeys;
          _error = null;
          _isBootstrapping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isBootstrapping = false;
        });
      }
    }
  }

  Future<void> _deletePasskey(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('remove_passkey_title'),
          style: AppTextStyles.bodyLarge(context),
        ),
        content: Text(
          _t('remove_passkey_confirm'),
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel'), style: TextStyle(color: AppColors.subtext(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('remove'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _webauthn.deletePasskey(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('passkey_removed'))),
        );
      }
      _loadPasskeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('passkey_remove_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _registerPasskey() async {
    setState(() => _isBusy = true);
    try {
      await _webauthn.registerPasskey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('passkey_registered'))),
        );
      }
      _loadPasskeys();
    } on PasskeyUserCancelledException catch (_) {
      // User cancelled — silently dismiss, no message needed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('passkey_register_failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('passkeys')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      t('passkey_manage_subtitle'),
                      style: AppTextStyles.bodySmall(context),
                    ),
                    const SizedBox(height: 20),

                    // Add new passkey button
                    GestureDetector(
                      onTap: _isBusy ? null : _registerPasskey,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isBusy
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryPurple,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.add, color: AppColors.primaryPurple),
                            const SizedBox(width: 10),
                            Text(
                              t('add_passkey'),
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isBootstrapping)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Center(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodySmall(context),
                        ),
                      )
                    else if (_passkeys.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.key_outlined,
                                size: 48,
                                color: AppColors.subtext(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t('no_passkeys_yet'),
                                style: AppTextStyles.bodyLarge(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('add_passkey_empty'),
                                style: AppTextStyles.bodySmall(context),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._passkeys.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PasskeyCard(
                            name: p['deviceName'] as String? ?? 'Unknown Device',
                            createdAt: p['createdAt'] as String?,
                            lastUsedAt: p['lastUsedAt'] as String?,
                            onDelete: () => _deletePasskey(p['id'] as String),
                          ),
                        );
                      }),
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

class _PasskeyCard extends StatelessWidget {
  final String name;
  final String? createdAt;
  final String? lastUsedAt;
  final VoidCallback onDelete;

  const _PasskeyCard({
    required this.name,
    this.createdAt,
    this.lastUsedAt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.iconBg(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    color: AppColors.primaryPurple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t('passkey_added')} ${_formatDate(createdAt)}',
                        style: AppTextStyles.bodySmall(context),
                      ),
                      if (lastUsedAt != null)
                        Text(
                          '${t('passkey_last_used')} ${_formatDate(lastUsedAt)}',
                          style: AppTextStyles.bodySmall(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(context)),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(
                    t('remove'),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _SubPageTopBar extends StatelessWidget {
  final String title;
  const _SubPageTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
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
                size: 22,
                color: AppColors.text(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
