import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

class VehicleClass {
  final String id;
  final String name;
  final double multiplier;

  VehicleClass({
    required this.id,
    required this.name,
    required this.multiplier,
  });

  factory VehicleClass.fromJson(Map<String, dynamic> json) {
    return VehicleClass(
      id: json['id'] as String,
      name: json['name'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
    );
  }
}

class VehicleClassDetail {
  final String id;
  final String name;
  final String? imageUrl;
  final double multiplier;
  final VehicleFeatures features;

  VehicleClassDetail({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.multiplier,
    required this.features,
  });

  factory VehicleClassDetail.fromJson(Map<String, dynamic> json) {
    return VehicleClassDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      multiplier: (json['multiplier'] as num).toDouble(),
      features: VehicleFeatures.fromJson(
        json['features'] as Map<String, dynamic>,
      ),
    );
  }
}

class VehicleFeatures {
  final int? seats;
  final int? bags;
  final bool? wifi;
  final bool? ac;
  final bool? water;
  final int? freeWaitingTime;
  final bool? doorToDoor;
  final bool? meetAndGreet;
  final List<ExtraFeature> extraFeatures;
  final List<ExtraFeature> extraServices;

  VehicleFeatures({
    this.seats,
    this.bags,
    this.wifi,
    this.ac,
    this.water,
    this.freeWaitingTime,
    this.doorToDoor,
    this.meetAndGreet,
    required this.extraFeatures,
    required this.extraServices,
  });

  factory VehicleFeatures.fromJson(Map<String, dynamic> json) {
    return VehicleFeatures(
      seats: json['seats'] as int?,
      bags: json['bags'] as int?,
      wifi: json['wifi'] as bool?,
      ac: json['ac'] as bool?,
      water: json['water'] as bool?,
      freeWaitingTime: json['freeWaitingTime'] as int?,
      doorToDoor: json['doorToDoor'] as bool?,
      meetAndGreet: json['meetAndGreet'] as bool?,
      extraFeatures:
          (json['extraFeatures'] as List<dynamic>?)
              ?.map((e) => ExtraFeature.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extraServices:
          (json['extraServices'] as List<dynamic>?)
              ?.map((e) => ExtraFeature.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ExtraFeature {
  final String name;
  final bool enabled;

  ExtraFeature({required this.name, required this.enabled});

  factory ExtraFeature.fromJson(Map<String, dynamic> json) {
    return ExtraFeature(
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
    );
  }
}

class VehicleClassesService {
  Future<List<VehicleClass>> getActiveClasses() async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/admin/classes/active-multipliers',
      );

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as List;
        return json
            .map((e) => VehicleClass.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching vehicle classes: $e');
    }
    return [];
  }

  Future<VehicleClassDetail?> getClassDetails(String classId) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${AppConfig.baseUrl}/classes/$classId/public');

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return VehicleClassDetail.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error fetching vehicle class details: $e');
    }
    return null;
  }
}
