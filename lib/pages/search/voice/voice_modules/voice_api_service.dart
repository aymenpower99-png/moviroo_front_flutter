// voice_modules/voice_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'voice_constants.dart';
import 'voice_logger.dart';

class VoiceApiService {

  static Future<Map<String, dynamic>> transcribe(String filePath) async {
    voiceLog('API', 'POST /transcribe  →  $filePath');
    return _sendFile(Uri.parse('$kBackendUrl/transcribe'), filePath);
  }

  static Future<Map<String, dynamic>> answer(
    String filePath, {
    required String field,
    required String language,
    String? destination,
    String? departure,
    String? date,
    String? time,
  }) async {
    // Validation stricte — jamais "undefined" ou "null"
    final String safeField = (field.isNotEmpty &&
        field != 'null' && field != 'undefined')
        ? field : 'destination';

    final String safeLang = (language.isNotEmpty &&
        language != 'null' && language != 'undefined' && language != 'un')
        ? language.substring(0, 2) : 'fr';

    final Map<String, String> params = {
      'field':    safeField,
      'language': safeLang,
    };
    if (destination != null && destination.isNotEmpty) params['destination'] = destination;
    if (departure   != null && departure.isNotEmpty)   params['departure']   = departure;
    if (date        != null && date.isNotEmpty)         params['date']        = date;
    if (time        != null && time.isNotEmpty)         params['time']        = time;

    final uri = Uri.parse('$kBackendUrl/answer').replace(queryParameters: params);

    voiceLog('API',
      'POST /answer\n'
      '║  URI      = $uri\n'
      '║  field    = $safeField\n'
      '║  language = $safeLang\n'
      '║  dest     = $destination\n'
      '║  dep      = $departure\n'
      '║  date     = $date\n'
      '║  time     = $time',
    );

    return _sendFile(uri, filePath);
  }

  static Future<Map<String, dynamic>> _sendFile(Uri uri, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('Audio file not found: $filePath');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final body     = await streamed.stream.bytesToString();

    voiceLog('API', 'HTTP ${streamed.statusCode}  ←  ${uri.path}');

    if (streamed.statusCode == 200) {
      final decoded = json.decode(body) as Map<String, dynamic>;
      voiceLogJson('API RAW RESPONSE', decoded);
      return decoded;
    }
    Map<String, dynamic> err = {};
    try { err = json.decode(body); } catch (_) {}
    throw Exception(err['detail'] ?? 'Server error ${streamed.statusCode}');
  }
}