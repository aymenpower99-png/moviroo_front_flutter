import 'package:flutter/material.dart';

enum TierStatus { locked, unlocked, current, used }

class MembershipTier {
  final String name;
  final int pointsRequired;
  final String discount;
  final TierStatus status;
  final Color accentColor;

  const MembershipTier({
    required this.name,
    required this.pointsRequired,
    required this.discount,
    required this.status,
    required this.accentColor,
  });
}

const List<MembershipTier> kMembershipTiers = [
  MembershipTier(
    name: 'Moviroo Go',
    pointsRequired: 500,
    discount: '5% discount',
    status: TierStatus.used,
    accentColor: Color(0xFF3B82F6), // Blue (good)
  ),
  MembershipTier(
    name: 'Moviroo Max',
    pointsRequired: 2000,
    discount: '15% discount',
    status: TierStatus.current,
    accentColor: Color(0xFFA855F7), // Purple (good)
  ),
  MembershipTier(
    name: 'Moviroo Elite',
    pointsRequired: 3000,
    discount: '20% discount',
    status: TierStatus.locked,
    accentColor: Color(0xFFFB8C00), // 🔥 Deep Orange (better than #FF9500)
  ),
  MembershipTier(
    name: 'Moviroo VIP',
    pointsRequired: 5000,
    discount: '25% discount',
    status: TierStatus.locked,
    accentColor: Color(0xFFF2C94C), // 🟡 Soft Gold (not too bright)
  ),
];