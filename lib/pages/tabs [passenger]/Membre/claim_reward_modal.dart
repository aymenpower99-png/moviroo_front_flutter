import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../services/membership/membership_service.dart';
import 'membership_tier.dart';
import 'claim_reward_modal_steps.dart';

/// Shows a two-step modal:
///   Step 1 → confirm claim  (Cancel / Claim Now)
///   Step 2 → code revealed  (Copy Code / Done)
///
/// Returns the generated [promoCode] when Done is pressed, or null on cancel.
Future<String?> showClaimRewardModal(
  BuildContext context,
  MembershipTier tier,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ClaimRewardModal(tier: tier),
  );
}

class _ClaimRewardModal extends StatefulWidget {
  final MembershipTier tier;
  const _ClaimRewardModal({required this.tier});

  @override
  State<_ClaimRewardModal> createState() => _ClaimRewardModalState();
}

enum _ModalStep { confirm, loading, revealed, error }

class _ClaimRewardModalState extends State<_ClaimRewardModal>
    with SingleTickerProviderStateMixin {

  _ModalStep _step = _ModalStep.confirm;
  String _promoCode = '';
  String _errorMsg  = '';
  bool _codeCopied = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onClaimNow() async {
    setState(() => _step = _ModalStep.loading);
    try {
      final result = await MembershipService.claimLevel(widget.tier.id);
      if (!mounted) return;
      setState(() {
        _promoCode = result.code;
        _step = _ModalStep.revealed;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
        _step = _ModalStep.error;
      });
    }
  }

  void _onCopy() {
    setState(() => _codeCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_step) {
      case _ModalStep.confirm:
        return ClaimConfirmView(
          tier: widget.tier,
          isDark: isDark,
          onCancel: () => Navigator.of(context).pop(null),
          onClaim: _onClaimNow,
        );
      case _ModalStep.loading:
        return ClaimLoadingView(tier: widget.tier);
      case _ModalStep.error:
        return _ClaimErrorView(
          message: _errorMsg,
          onDismiss: () => Navigator.of(context).pop(null),
        );
      case _ModalStep.revealed:
        return FadeTransition(
          opacity: _fadeAnim,
          child: ClaimRevealedView(
            tier: widget.tier,
            promoCode: _promoCode,
            copied: _codeCopied,
            isDark: isDark,
            onCopy: _onCopy,
            onDone: () => Navigator.of(context).pop(_promoCode),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _buildBody(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ClaimErrorView({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Could not claim reward',
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700,
            color: AppColors.text(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.subtext(context)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: const Text('OK', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
