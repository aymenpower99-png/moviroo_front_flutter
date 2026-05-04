import 'dart:convert';
import '../auth/auth_http.dart';

/// A single membership level returned from the backend.
class MembershipLevelData {
  final String id;
  final String name;
  final int requiredPoints;
  final double discountPercentage;
  final int level;
  final bool isActive;

  const MembershipLevelData({
    required this.id,
    required this.name,
    required this.requiredPoints,
    required this.discountPercentage,
    required this.level,
    required this.isActive,
  });

  factory MembershipLevelData.fromJson(Map<String, dynamic> json) {
    final rawDiscount = json['discountPercentage'];
    final discount = rawDiscount is String
        ? double.tryParse(rawDiscount) ?? 0.0
        : (rawDiscount as num? ?? 0).toDouble();

    return MembershipLevelData(
      id:                 json['id'] as String,
      name:               json['name'] as String,
      requiredPoints:     (json['requiredPoints'] as num).toInt(),
      discountPercentage: discount,
      level:              (json['level'] as num).toInt(),
      isActive:           json['isActive'] as bool,
    );
  }
}

/// The full membership info response for the current passenger.
class MembershipInfo {
  final int userPoints;
  final int remainingPoints;
  final int totalPoints;
  final String currentLevelName;
  final MembershipLevelData? currentLevel;
  final MembershipLevelData? nextLevel;
  final int? pointsToNext;
  final double progressPercent;
  final List<MembershipLevelData> levels;
  /// Level IDs that have an ACTIVE (unclaimed) coupon.
  final List<String> claimedLevelIds;
  /// Maps levelId → coupon code for ACTIVE coupons (restored after page refresh).
  final Map<String, String> activeCouponCodes;

  const MembershipInfo({
    required this.userPoints,
    required this.remainingPoints,
    required this.totalPoints,
    required this.currentLevelName,
    required this.currentLevel,
    required this.nextLevel,
    required this.pointsToNext,
    required this.progressPercent,
    required this.levels,
    required this.claimedLevelIds,
    required this.activeCouponCodes,
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      userPoints:        (json['userPoints'] as num).toInt(),
      remainingPoints:   (json['remainingPoints'] as num? ?? 0).toInt(),
      totalPoints:       (json['totalPoints'] as num? ?? 0).toInt(),
      currentLevelName:  json['currentLevelName'] as String,
      currentLevel:      json['currentLevel'] != null
          ? MembershipLevelData.fromJson(
              json['currentLevel'] as Map<String, dynamic>)
          : null,
      nextLevel:         json['nextLevel'] != null
          ? MembershipLevelData.fromJson(
              json['nextLevel'] as Map<String, dynamic>)
          : null,
      pointsToNext:      json['pointsToNext'] != null
          ? (json['pointsToNext'] as num).toInt()
          : null,
      progressPercent:   (json['progressPercent'] as num? ?? 0).toDouble(),
      levels: (json['levels'] as List<dynamic>)
          .map((e) => MembershipLevelData.fromJson(e as Map<String, dynamic>))
          .toList(),
      claimedLevelIds: (json['claimedLevelIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      activeCouponCodes: (json['activeCouponCodes'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
    );
  }

  factory MembershipInfo.empty() {
    return const MembershipInfo(
      userPoints:          0,
      remainingPoints:     0,
      totalPoints:         0,
      currentLevelName:    'Moviroo Starter',
      currentLevel:        null,
      nextLevel:           null,
      pointsToNext:        null,
      progressPercent:     0.0,
      levels:              [],
      claimedLevelIds:     [],
      activeCouponCodes:   {},
    );
  }
}

/// Response from claim endpoint.
class ClaimedCoupon {
  final String code;
  final double discountPercentage;
  final int level;

  const ClaimedCoupon({
    required this.code,
    required this.discountPercentage,
    required this.level,
  });

  factory ClaimedCoupon.fromJson(Map<String, dynamic> json) {
    final rawDiscount = json['discountPercentage'];
    return ClaimedCoupon(
      code:               json['code'] as String,
      discountPercentage: rawDiscount is String
          ? double.tryParse(rawDiscount) ?? 0.0
          : (rawDiscount as num? ?? 0).toDouble(),
      level: (json['level'] as num).toInt(),
    );
  }
}

/// Response from validate (apply) coupon endpoint.
class CouponValidation {
  final String code;
  final double discountPercentage;
  final int level;

  const CouponValidation({
    required this.code,
    required this.discountPercentage,
    required this.level,
  });

  factory CouponValidation.fromJson(Map<String, dynamic> json) {
    final rawDiscount = json['discountPercentage'];
    return CouponValidation(
      code:               json['code'] as String,
      discountPercentage: rawDiscount is String
          ? double.tryParse(rawDiscount) ?? 0.0
          : (rawDiscount as num? ?? 0).toDouble(),
      level: (json['level'] as num).toInt(),
    );
  }
}

class MembershipService {
  /// GET /passengers/me/membership
  static Future<MembershipInfo> getMembershipInfo() async {
    final response = await AuthHTTP.authenticatedGet('/passengers/me/membership');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MembershipInfo.fromJson(data);
    }

    throw Exception('Failed to load membership info (${response.statusCode})');
  }

  /// POST /passengers/me/membership/:levelId/claim
  static Future<ClaimedCoupon> claimLevel(String levelId) async {
    final response = await AuthHTTP.authenticatedPost(
      '/passengers/me/membership/$levelId/claim',
      {},
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ClaimedCoupon.fromJson(data);
    }

    final body = jsonDecode(response.body);
    final msg  = body['message'] ?? 'Failed to claim level';
    throw Exception(msg is List ? (msg as List).join(' ') : msg.toString());
  }

  /// POST /passengers/me/coupons/apply — validate without marking used
  static Future<CouponValidation> validateCoupon(String code) async {
    final response = await AuthHTTP.authenticatedPost(
      '/passengers/me/coupons/apply',
      {'code': code.toUpperCase()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CouponValidation.fromJson(data);
    }

    final body = jsonDecode(response.body);
    final msg  = body['message'] ?? 'Invalid coupon code';
    throw Exception(msg is List ? (msg as List).join(' ') : msg.toString());
  }

  /// PATCH /passengers/me/coupons/:code/use — mark coupon as used
  static Future<void> useCoupon(String code) async {
    final response = await AuthHTTP.authenticatedPatch(
      '/passengers/me/coupons/${code.toUpperCase()}/use',
      {},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = jsonDecode(response.body);
      final msg  = body['message'] ?? 'Failed to use coupon';
      throw Exception(msg is List ? (msg as List).join(' ') : msg.toString());
    }
  }
}

