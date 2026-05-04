import 'package:flutter/material.dart';
import '../../../services/membership/membership_service.dart';

const List<int> _kTierColors = [
  0xFF3B82F6,
  0xFFA855F7,
  0xFFFB8C00,
  0xFFF2C94C,
];

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

  factory MembershipTier.fromLevel(
    MembershipLevelData level,
    int index,
    int userPoints,
    MembershipLevelData? currentLevel,
  ) {
    final TierStatus status;
    if (currentLevel != null && level.order < currentLevel.order) {
      status = TierStatus.used;
    } else if (currentLevel != null && level.order == currentLevel.order) {
      status = TierStatus.current;
    } else if (userPoints >= level.requiredPoints) {
      status = TierStatus.unlocked;
    } else {
      status = TierStatus.locked;
    }

    return MembershipTier(
      name: level.name,
      pointsRequired: level.requiredPoints,
      discount:
          '${level.discountPercentage.toStringAsFixed(0)}% OFF on your next rides',
      status: status,
      accentColor: Color(_kTierColors[index % _kTierColors.length]),
    );
  }
}

/// Runtime mutable state for a tier (claimed + promo code).
class TierClaimState {
  final bool claimed;
  final String? promoCode;

  const TierClaimState({this.claimed = false, this.promoCode});

  TierClaimState copyWith({bool? claimed, String? promoCode}) => TierClaimState(
        claimed: claimed ?? this.claimed,
        promoCode: promoCode ?? this.promoCode,
      );
}

/// Generates a deterministic-looking promo code for a tier.
String generatePromoCode(String tierName) {
  final prefix = tierName
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase())
      .join('');
  final suffix = (DateTime.now().millisecondsSinceEpoch % 10000)
      .toString()
      .padLeft(4, '0');
  return 'MOV-$prefix-$suffix';
}