import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
    final browserName = webInfo.browserName.name;
    final platform = webInfo.platform;
    return '$browserName on $platform';
  }

  Future<Map<String, String>> _getWebDeviceInfo() async {
    final webInfo = await DeviceInfoPlugin().webBrowserInfo;
    return {
      'platform': 'Web',
      'device': webInfo.browserName.name,
      'userAgent': webInfo.userAgent ?? 'Unknown',
    };
  }

  Future<String> _getAndroidDeviceName() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final brand = androidInfo.brand.trim();
    final model = androidInfo.model.trim();
    final product = androidInfo.product.trim();
    final manufacturer = androidInfo.manufacturer.trim();

    // Try to create a readable device name with multiple fallbacks
    if (brand.isNotEmpty && model.isNotEmpty) {
      return '$brand $model';
    } else if (manufacturer.isNotEmpty && model.isNotEmpty) {
      return '$manufacturer $model';
    } else if (product.isNotEmpty) {
      return product;
    } else if (model.isNotEmpty) {
      return model;
    } else if (brand.isNotEmpty) {
      return brand;
    } else {
      return 'Android Device';
    }
  }

  Future<Map<String, String>> _getAndroidDeviceInfo() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return {
      'platform': 'Android',
      'device': androidInfo.model,
      'brand': androidInfo.brand,
      'manufacturer': androidInfo.manufacturer,
      'product': androidInfo.product,
      'version': androidInfo.version.release,
      'sdkInt': androidInfo.version.sdkInt.toString(),
    };
  }

  Future<String> _getIOSDeviceName() async {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    final model = iosInfo.model.trim();
    final name = iosInfo.name.trim();
    final systemName = iosInfo.systemName.trim();

    // Try to use the device name if available, otherwise use model
    if (name.isNotEmpty && name != 'iPhone' && name != 'iPad') {
      return name;
    } else if (model.isNotEmpty) {
      return model;
    } else if (systemName.isNotEmpty) {
      return systemName;
    } else {
      return 'iOS Device';
    }
  }

  Future<Map<String, String>> _getIOSDeviceInfo() async {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    return {
      'platform': 'iOS',
      'device': iosInfo.model,
      'name': iosInfo.name,
      'systemName': iosInfo.systemName,
      'systemVersion': iosInfo.systemVersion,
      'model': iosInfo.model,
    };
  }

  /// Get a stable device identifier for session deduplication.
  /// Android → androidId, iOS → identifierForVendor, Web → persisted UUID.
  Future<String> getDeviceId() async {
    try {
      if (kIsWeb) {
        return await _getOrCreateWebDeviceId();
      } else if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final id = androidInfo.id;
        if (id.isNotEmpty) return id;
        return await _fallbackPersistedId();
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        final id = iosInfo.identifierForVendor;
        if (id != null && id.isNotEmpty) return id;
        return await _fallbackPersistedId();
      } else {
        return await _fallbackPersistedId();
      }
    } catch (e) {
      debugPrint('Error getting device id: $e');
      return await _fallbackPersistedId();
    }
  }

  /// Return both device name and id in one call for login headers.
  Future<Map<String, String>> getDeviceHeaders() async {
    final deviceName = await getDeviceName();
    final deviceId = await getDeviceId();
    final platform = getPlatform();
    return {
      'X-Device-Name': deviceName,
      'X-Device-Id': deviceId,
      'X-Device-Platform': platform,
    };
  }

  Future<String> _getOrCreateWebDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('_moviroo_device_id');
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await prefs.setString('_moviroo_device_id', id);
    return id;
  }

  Future<String> _fallbackPersistedId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('_moviroo_device_id');
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await prefs.setString('_moviroo_device_id', id);
    return id;
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
