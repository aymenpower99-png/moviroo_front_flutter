import 'dart:convert';
import '../auth/auth_http.dart';

/// A single membership level returned from the backend.
class MembershipLevelData {
  final String id;
  final String name;
  final int requiredPoints;
  final double discountPercentage;
  final int order;
  final bool isActive;

  const MembershipLevelData({
    required this.id,
    required this.name,
    required this.requiredPoints,
    required this.discountPercentage,
    required this.order,
    required this.isActive,
  });

  factory MembershipLevelData.fromJson(Map<String, dynamic> json) {
    // discountPercentage comes as decimal string from PostgreSQL ("10.00")
    final rawDiscount = json['discountPercentage'];
    final discount = rawDiscount is String
        ? double.tryParse(rawDiscount) ?? 0.0
        : (rawDiscount as num? ?? 0).toDouble();

    return MembershipLevelData(
      id:                 json['id'] as String,
      name:               json['name'] as String,
      requiredPoints:     (json['requiredPoints'] as num).toInt(),
      discountPercentage: discount,
      order:              (json['order'] as num).toInt(),
      isActive:           json['isActive'] as bool,
    );
  }
}

/// The full membership info response for the current passenger.
class MembershipInfo {
  final int userPoints;
  final String currentLevelName;
  final MembershipLevelData? currentLevel;
  final MembershipLevelData? nextLevel;
  final int? pointsToNext;
  final double progressPercent;
  final List<MembershipLevelData> levels;

  const MembershipInfo({
    required this.userPoints,
    required this.currentLevelName,
    required this.currentLevel,
    required this.nextLevel,
    required this.pointsToNext,
    required this.progressPercent,
    required this.levels,
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      userPoints:        (json['userPoints'] as num).toInt(),
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
    );
  }

  /// Fallback: no levels exist in DB yet.
  factory MembershipInfo.empty() {
    return const MembershipInfo(
      userPoints:       0,
      currentLevelName: 'Moviroo Starter',
      currentLevel:     null,
      nextLevel:        null,
      pointsToNext:     null,
      progressPercent:  0.0,
      levels:           [],
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

    throw Exception(
      'Failed to load membership info (${response.statusCode})',
    );
  }
}
