import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth/webauthn_service.dart';

class PasskeyManagementPage extends StatefulWidget {
  const PasskeyManagementPage({super.key});

  @override
  State<PasskeyManagementPage> createState() => _PasskeyManagementPageState();
}

class _PasskeyManagementPageState extends State<PasskeyManagementPage> {
  final _webauthn = WebAuthnService();
  List<dynamic> _passkeys = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPasskeys();
  }

  Future<void> _loadPasskeys() async {
    setState(() => _isLoading = true);
    try {
      final passkeys = await _webauthn.getPasskeys();
      setState(() {
        _passkeys = passkeys;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePasskey(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Passkey?',
          style: AppTextStyles.bodyLarge(context),
        ),
        content: Text(
          'This passkey will no longer be available for passwordless sign-in.',
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtext(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _webauthn.deletePasskey(id);
      _loadPasskeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove passkey: $e')),
        );
      }
    }
  }

  Future<void> _renamePasskey(String id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename Passkey', style: AppTextStyles.bodyLarge(context)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Device name',
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtext(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save', style: TextStyle(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty) return;

    try {
      await _webauthn.renamePasskey(id, newName);
      _loadPasskeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename passkey: $e')),
        );
      }
    }
  }

  Future<void> _registerPasskey() async {
    setState(() => _isLoading = true);
    try {
      await _webauthn.registerPasskey(
        deviceName: 'Passkey ${DateTime.now().year}',
      );
      _loadPasskeys();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passkey registered successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register passkey: $e')),
        );
      }
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
            _SubPageTopBar(title: 'Passkeys'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Manage your passkeys for passwordless sign-in.',
                      style: AppTextStyles.bodySmall(context),
                    ),
                    const SizedBox(height: 20),

                    // Add new passkey button
                    GestureDetector(
                      onTap: _isLoading ? null : _registerPasskey,
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
                            Icon(Icons.add, color: AppColors.primaryPurple),
                            const SizedBox(width: 10),
                            Text(
                              'Add Passkey',
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isLoading && _passkeys.isEmpty)
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
                                'No passkeys yet',
                                style: AppTextStyles.bodyLarge(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add a passkey for passwordless sign-in.',
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
                            onRename: () => _renamePasskey(
                              p['id'] as String,
                              p['deviceName'] as String? ?? 'Unknown Device',
                            ),
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
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PasskeyCard({
    required this.name,
    this.createdAt,
    this.lastUsedAt,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                        'Added ${_formatDate(createdAt)}',
                        style: AppTextStyles.bodySmall(context),
                      ),
                      if (lastUsedAt != null)
                        Text(
                          'Last used ${_formatDate(lastUsedAt)}',
                          style: AppTextStyles.bodySmall(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(context)),
          Row(
            children: [
              Expanded(
                child: _TileAction(
                  icon: Icons.edit_outlined,
                  label: 'Rename',
                  color: AppColors.primaryPurple,
                  onTap: onRename,
                ),
              ),
              VerticalDivider(width: 1, color: AppColors.border(context)),
              Expanded(
                child: _TileAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove',
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ),
            ],
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

class _TileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
