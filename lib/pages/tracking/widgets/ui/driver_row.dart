import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../widgets/driver_avatar.dart';

/// A bordered modern card showing driver avatar, name, vehicle info, and
/// action buttons (phone + chat). Matches the pickup/dropoff card style.
class DriverRow extends StatelessWidget {
  final String driverName;
  final String vehicleName;
  final String vehicleMake;
  final String vehicleModel;

  /// Optional — shown below [vehicleName]. Rendered prominently when
  /// [isArrived] is `true`.
  final String? plateNumber;

  /// When `true` the plate number is highlighted.
  final bool isArrived;

  final String? driverId;
  final VoidCallback? onPhoneTap;
  final VoidCallback? onChatTap;
  final String? driverPhotoUrl;
  final double driverRating;

  const DriverRow({
    super.key,
    required this.driverName,
    this.driverId,
    required this.vehicleName,
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.plateNumber,
    this.isArrived = false,
    this.onPhoneTap,
    this.onChatTap,
    this.driverPhotoUrl,
    this.driverRating = 0.0,
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
          // ── Left: driver avatar with rating badge below ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              DriverAvatar(
                name: driverName,
                driverId: driverId,
                photoUrl: driverPhotoUrl,
                size: 44,
              ),
              if (driverRating > 0)
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            driverRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
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

    // Maker Model (space between, no dot)
    if (vehicleMake.isNotEmpty && vehicleModel.isNotEmpty) {
      parts.add('$vehicleMake $vehicleModel');
    } else if (vehicleMake.isNotEmpty) {
      parts.add(vehicleMake);
    } else if (vehicleModel.isNotEmpty) {
      parts.add(vehicleModel);
    } else if (vehicleName.isNotEmpty) {
      parts.add(vehicleName);
    }

    return parts.join(' · ');
  }
}

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
          shape: BoxShape.circle,
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
          shape: BoxShape.circle,
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
