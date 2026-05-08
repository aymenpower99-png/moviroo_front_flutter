import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for capturing detailed device information for session tracking.
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  /// Get a human-readable device name for the current device.
  /// This includes device model, brand, and operating system.
  Future<String> getDeviceName() async {
    try {
      if (kIsWeb) {
        return _getWebDeviceName();
      } else if (Platform.isAndroid) {
        return await _getAndroidDeviceName();
      } else if (Platform.isIOS) {
        return await _getIOSDeviceName();
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      debugPrint('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  /// Get detailed device information as a map.
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return await _getWebDeviceInfo();
      } else if (Platform.isAndroid) {
        return await _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return await _getIOSDeviceInfo();
      } else {
        return {'platform': 'Unknown', 'device': 'Unknown Device'};
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {'platform': 'Unknown', 'device': 'Unknown Device'};
    }
  }

  Future<String> _getWebDeviceName() async {
    final webInfo = await DeviceInfoPlugin().webBrowserInfo;
    final browserName = webInfo.browserName?.name ?? 'Unknown Browser';
    final platform = webInfo.platform ?? 'Web';
    return '$browserName on $platform';
  }

  Future<Map<String, String>> _getWebDeviceInfo() async {
    final webInfo = await DeviceInfoPlugin().webBrowserInfo;
    return {
      'platform': 'Web',
      'device': webInfo.browserName?.name ?? 'Unknown Browser',
      'userAgent': webInfo.userAgent ?? 'Unknown',
    };
  }

  Future<String> _getAndroidDeviceName() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final brand = androidInfo.brand;
    final model = androidInfo.model;
    final product = androidInfo.product;
    
    // Try to create a readable device name
    if (brand != null && model != null) {
      return '$brand $model';
    } else if (product != null) {
      return product;
    } else {
      return 'Android Device';
    }
  }

  Future<Map<String, String>> _getAndroidDeviceInfo() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return {
      'platform': 'Android',
      'device': androidInfo.model ?? 'Android Device',
      'brand': androidInfo.brand ?? 'Unknown',
      'manufacturer': androidInfo.manufacturer ?? 'Unknown',
      'product': androidInfo.product ?? 'Unknown',
      'version': androidInfo.version.release ?? 'Unknown',
      'sdkInt': androidInfo.version.sdkInt.toString(),
    };
  }

  Future<String> _getIOSDeviceName() async {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    final model = iosInfo.model;
    final name = iosInfo.name;
    
    // Try to use the device name if available, otherwise use model
    if (name != null && name.isNotEmpty) {
      return name;
    } else if (model != null) {
      return model;
    } else {
      return 'iOS Device';
    }
  }

  Future<Map<String, String>> _getIOSDeviceInfo() async {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    return {
      'platform': 'iOS',
      'device': iosInfo.model ?? 'iOS Device',
      'name': iosInfo.name ?? 'Unknown',
      'systemName': iosInfo.systemName ?? 'iOS',
      'systemVersion': iosInfo.systemVersion ?? 'Unknown',
      'model': iosInfo.model ?? 'Unknown',
    };
  }

  /// Get a short platform identifier (e.g., 'Android', 'iOS', 'Web')
  String getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
