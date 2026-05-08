import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:moviroo/pages/search/voice/constants.dart';
import 'package:moviroo/pages/search/voice/logger.dart';


// ─────────────────────────────────────────────────────────────
// API Service
// ─────────────────────────────────────────────────────────────
class ApiService {
  /// POST /transcribe — envoie l'audio initial et retourne le résultat complet
  static Future<Map<String, dynamic>> transcribe(String filePath) {
    appLog('API', 'POST /transcribe  →  $filePath');
    return _sendFile(Uri.parse('$kBackendUrl/transcribe'), filePath);
  }

  /// POST /answer — envoie la réponse à une question de complément
  static Future<Map<String, dynamic>> answer(
    String filePath, {
    required String field,
    required String language,
    String? destination,
    String? departure,
    String? date,
    String? time,
  }) {
    final params = {
      'field': field,
      'language': language,
      if (destination != null) 'destination': destination,
      if (departure   != null) 'departure':   departure,
      if (date        != null) 'date':         date,
      if (time        != null) 'time':         time,
    };
    appLog('API', 'POST /answer  →  field=$field  params=$params');
    final uri = Uri.parse('$kBackendUrl/answer')
        .replace(queryParameters: params);
    return _sendFile(uri, filePath);
  }

  // ── Méthode interne ───────────────────────────────────────
  static Future<Map<String, dynamic>> _sendFile(
      Uri uri, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $filePath');
    }

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed =
        await request.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();

    appLog('API', 'HTTP ${streamed.statusCode}  ←  ${uri.path}');

    if (streamed.statusCode == 200) {
      final decoded = json.decode(body) as Map<String, dynamic>;
      appLogJson('API RAW RESPONSE', decoded);
      return decoded;
    }

    Map<String, dynamic> err = {};
    try {
      err = json.decode(body);
    } catch (_) {}
    throw Exception(err['detail'] ?? 'Server error ${streamed.statusCode}');
  }
}
