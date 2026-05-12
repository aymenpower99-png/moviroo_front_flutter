import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';

/// A bordered modern card showing driver avatar, name, vehicle info, and
/// action buttons (phone + chat). Matches the pickup/dropoff card style.
class DriverRow extends StatelessWidget {
  final String driverName;
  final String vehicleName;

  /// Optional — shown below [vehicleName]. Rendered prominently when
  /// [isArrived] is `true`.
  final String? plateNumber;

  /// When `true` the plate number is highlighted.
  final bool isArrived;

  final VoidCallback? onPhoneTap;
  final VoidCallback? onChatTap;

  const DriverRow({
    super.key,
    required this.driverName,
    required this.vehicleName,
    this.plateNumber,
    this.isArrived = false,
    this.onPhoneTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          // ── Left: circular purple icon container ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withValues(alpha: 0.10),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primaryPurple,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Center: name + vehicle info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _buildSubtitle(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.subtext(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Right: action buttons ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PhoneButton(onTap: onPhoneTap ?? () {}),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: onChatTap ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (vehicleName.isNotEmpty) parts.add(vehicleName);
    if (plateNumber != null && plateNumber!.isNotEmpty) parts.add(plateNumber!);
    return parts.join(' · ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: AppColors.primaryPurple),
        ),
      ),
    );
  }
}

class _PhoneButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PhoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            'images/icons/telephone.png',
            width: 18,
            height: 18,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}
