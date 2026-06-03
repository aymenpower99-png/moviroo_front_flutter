import 'package:flutter/services.dart';

class DownloadService {
  static const _channel = MethodChannel('com.moviroo/download');

  /// Download a file using Android's DownloadManager
  /// 
  /// [url] - The URL to download from
  /// [fileName] - The name to save the file as
  /// [authHeader] - Optional authorization header (e.g., "Bearer token")
  /// 
  /// Returns the download ID if successful, throws an exception otherwise
  static Future<int> downloadFile({
    required String url,
    required String fileName,
    String? authHeader,
  }) async {
    try {
      final result = await _channel.invokeMethod<int>('downloadFile', {
        'url': url,
        'fileName': fileName,
        'authHeader': authHeader,
      });
      
      if (result == null) {
        throw Exception('Download failed: No download ID returned');
      }
      
      return result;
    } on PlatformException catch (e) {
      throw Exception('Download failed: ${e.message}');
    }
  }
}
