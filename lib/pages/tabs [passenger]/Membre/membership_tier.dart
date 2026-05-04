import '../../../services/membership/membership_service.dart';

enum TierStatus { locked, unlocked, current, used }

class MembershipTier {
  final String id;
  final String name;
  final int pointsRequired;
  final String discount;
  final TierStatus status;

  const MembershipTier({
    required this.id,
    required this.name,
    required this.pointsRequired,
    required this.discount,
    required this.status,
  });

  factory MembershipTier.fromLevel(
    MembershipLevelData level,
    int userPoints,
    MembershipLevelData? currentLevel,
  ) {
    final TierStatus status;
    if (currentLevel != null && level.level < currentLevel.level) {
      status = TierStatus.used;
    } else if (currentLevel != null && level.level == currentLevel.level) {
      status = TierStatus.current;
    } else if (userPoints >= level.requiredPoints) {
      status = TierStatus.unlocked;
    } else {
      status = TierStatus.locked;
    }

    return MembershipTier(
      id: level.id,
      name: level.name,
      pointsRequired: level.requiredPoints,
      discount:
          '${level.discountPercentage.toStringAsFixed(0)}% OFF on your next rides',
      status: status,
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
