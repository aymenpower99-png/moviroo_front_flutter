import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';

/// A row showing driver avatar, name, vehicle, plate number, and action buttons.
///
/// When [isArrived] is `true` the plate number is rendered in bold + accent
/// color to surface the "driver is here" moment.
class DriverRow extends StatelessWidget {
  final String driverName;
  final String vehicleName;

  /// Optional — shown below [vehicleName].  Rendered prominently when
  /// [isArrived] is `true`.
  final String? plateNumber;

  /// When `true` the plate number is highlighted and a subtle green ring
  /// appears around the avatar.
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
    const green = Color(0xFF4ADE80);

    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.35),
              width: 2,
            ),
            color: AppColors.iconBg(context),
          ),
          child: ClipOval(
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primaryPurple,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Name + vehicle + plate
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
              ),
              const SizedBox(height: 2),
              Text(
                vehicleName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.subtext(context),
                ),
              ),
              if (plateNumber != null) ...[
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: isArrived ? FontWeight.w700 : FontWeight.w400,
                    color: isArrived
                        ? green
                        : Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                  child: Text(plateNumber!),
                ),
              ],
            ],
          ),
        ),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              asset: 'images/icons/phone-call.png',
              onTap: onPhoneTap ?? () {},
            ),
            const SizedBox(width: 10),
            _ActionButton(
              asset: 'images/icons/chat.png',
              onTap: onChatTap ?? () {},
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _ActionButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.border(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: ImageIcon(
            AssetImage(asset),
            size: 20,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}
