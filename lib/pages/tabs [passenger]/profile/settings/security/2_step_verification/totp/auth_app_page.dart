import 'package:flutter/material.dart';
import '../../../../../../../../../../theme/app_text_styles.dart';
import '../../../../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../../../../theme/app_colors.dart';
import '../../../../../../../../../../services/auth_service/auth_service.dart';
import 'widgets/setup_view.dart';
import 'widgets/linked_view.dart';
import 'widgets/confirm_unlink_dialog.dart';
import '../totp/shared/sub_page_top_bar.dart';

class AuthAppPage extends StatefulWidget {
  const AuthAppPage({super.key});

  @override
  State<AuthAppPage> createState() => _AuthAppPageState();
}

class _AuthAppPageState extends State<AuthAppPage> {
  final _authService = AuthService();

  bool _isLinked = false;
  final bool _isBootstrapping = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _setupSecret;
  String? _qrDataUrl;

  @override
  void initState() {
    super.initState();
    final cached = _authService.getCachedUser();
    final alreadyLinked = (cached?['totpEnabled'] as bool?) ?? false;
    if (alreadyLinked) {
      _isLinked = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    try {
      final cached = _authService.getCachedUser();
      final alreadyLinked = (cached?['totpEnabled'] as bool?) ?? false;

      if (alreadyLinked) {
        if (!mounted) return;
        setState(() => _isLinked = true);
        return;
      }

      final data = await _authService.setupTotp();
      if (!mounted) return;
      setState(() {
        _setupSecret = data['secret'] as String?;
        _qrDataUrl = data['qrCodeUrl'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleLink(String code) async {
    if (_isLoading) return;
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.confirmTotp(code);
      if (!mounted) return;
      // Reset loading BEFORE pop to avoid setState on disposing widget
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).translate('authenticator_app_linked_success'),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleUnlink() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const ConfirmUnlinkDialog(),
    );

    if (code == null || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.disableTotp(code: code);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLinked = false;
      });
      final data = await _authService.setupTotp();
      if (!mounted) return;
      setState(() {
        _setupSecret = data['secret'] as String?;
        _qrDataUrl = data['qrCodeUrl'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
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
            SubPageTopBar(title: t('Authentication App')),
            Expanded(
              child: _isBootstrapping
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isLinked
                          ? LinkedView(
                              isLoading: _isLoading,
                              onUnlink: _handleUnlink,
                            )
                          : SetupView(
                              secret: _setupSecret ?? '',
                              qrDataUrl: _qrDataUrl,
                              isLoading: _isLoading,
                              errorMessage: _errorMessage,
                              onLink: _handleLink,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
