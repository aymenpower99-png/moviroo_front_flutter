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
    discount: '10% OFF on your next rides',
    status: TierStatus.used,
    accentColor: Color(0xFF3B82F6),
  ),
  MembershipTier(
    name: 'Moviroo Max',
    pointsRequired: 2000,
    discount: '15% OFF on your next rides',
    status: TierStatus.current,
    accentColor: Color(0xFFA855F7),
  ),
  MembershipTier(
    name: 'Moviroo Elite',
    pointsRequired: 3000,
    discount: '20% OFF on your next rides',
    status: TierStatus.locked,
    accentColor: Color(0xFFFB8C00),
  ),
  MembershipTier(
    name: 'Moviroo VIP',
    pointsRequired: 5000,
    discount: '25% OFF on your next rides',
    status: TierStatus.locked,
    accentColor: Color(0xFFF2C94C),
  ),
];

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