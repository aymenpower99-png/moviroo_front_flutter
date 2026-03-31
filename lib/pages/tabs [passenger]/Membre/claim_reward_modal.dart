import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
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

enum _ModalStep { confirm, loading, revealed }

class _ClaimRewardModalState extends State<_ClaimRewardModal>
    with SingleTickerProviderStateMixin {

  _ModalStep _step = _ModalStep.confirm;
  late final String _promoCode;
  bool _codeCopied = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _promoCode = generatePromoCode(widget.tier.name);
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
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _step = _ModalStep.revealed);
    _fadeCtrl.forward();
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