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
    final String safeField =
        (field.isNotEmpty && field != 'null' && field != 'undefined')
        ? field
        : 'destination';

    final String safeLang =
        (language.isNotEmpty &&
            language != 'null' &&
            language != 'undefined' &&
            language != 'un')
        ? language.substring(0, 2)
        : 'fr';

    final uri = Uri.parse('$kBackendUrl/answer');

    voiceLog(
      'API',
      'POST /answer\n'
          '║  URI      = $uri\n'
          '║  field    = $safeField\n'
          '║  language = $safeLang\n'
          '║  dest     = $destination\n'
          '║  dep      = $departure\n'
          '║  date     = $date\n'
          '║  time     = $time',
    );

    return _sendFileWithFields(uri, filePath, {
      'field': safeField,
      'language': safeLang,
      if (destination != null && destination.isNotEmpty)
        'destination': destination,
      if (departure != null && departure.isNotEmpty) 'departure': departure,
      if (date != null && date.isNotEmpty) 'date': date,
      if (time != null && time.isNotEmpty) 'time': time,
    });
  }

  /// Send file only (transcribe)
  static Future<Map<String, dynamic>> _sendFile(
    Uri uri,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists())
      throw Exception('Audio file not found: $filePath');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    return _execute(request, uri);
  }

  /// Send file + form fields (answer) — NestJS @Body() reads multipart fields
  static Future<Map<String, dynamic>> _sendFileWithFields(
    Uri uri,
    String filePath,
    Map<String, String> fields,
  ) async {
    final file = File(filePath);
    if (!await file.exists())
      throw Exception('Audio file not found: $filePath');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath))
      ..fields.addAll(fields);

    return _execute(request, uri);
  }

  static Future<Map<String, dynamic>> _execute(
    http.MultipartRequest request,
    Uri uri,
  ) async {
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();

    voiceLog('API', 'HTTP ${streamed.statusCode}  ←  ${uri.path}');

    if (streamed.statusCode == 200) {
      final decoded = json.decode(body) as Map<String, dynamic>;
      voiceLogJson('API RAW RESPONSE', decoded);
      return decoded;
    }
    Map<String, dynamic> err = {};
    try {
      err = json.decode(body);
    } catch (_) {}
    throw Exception(err['detail'] ?? 'Server error ${streamed.statusCode}');
  }
}
