import 'dart:convert';
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
        return json.map((e) => VehicleClass.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Error fetching vehicle classes: $e');
    }
    return [];
  }
}
