import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  // Get comprehensive device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      Map<String, dynamic> deviceData = {
        'app_name': packageInfo.appName,
        'package_name': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData.addAll({
          'device_type': 'android',
          'device_id': androidInfo.id,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'product': androidInfo.product,
          'device': androidInfo.device,
          'hardware': androidInfo.hardware,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'security_patch': androidInfo.version.securityPatch,
          'fingerprint': androidInfo.fingerprint,
          'is_physical_device': androidInfo.isPhysicalDevice,
          'supported_abis': androidInfo.supportedAbis,
          'system_features': androidInfo.systemFeatures,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData.addAll({
          'device_type': 'ios',
          'device_id': iosInfo.identifierForVendor,
          'name': iosInfo.name,
          'model': iosInfo.model,
          'localized_model': iosInfo.localizedModel,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
          'utsname': {
            'sysname': iosInfo.utsname.sysname,
            'nodename': iosInfo.utsname.nodename,
            'release': iosInfo.utsname.release,
            'version': iosInfo.utsname.version,
            'machine': iosInfo.utsname.machine,
          },
        });
      }

      return deviceData;
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {
        'platform': Platform.operatingSystem,
        'error': 'Failed to get device info',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get unique device identifier
  Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }

      return 'unknown_device';
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return 'error_device_id';
    }
  }

  // Check if device is physical (not emulator/simulator)
  Future<bool> isPhysicalDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.isPhysicalDevice;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking physical device: $e');
      return false;
    }
  }

  // Get device model for display
  Future<String> getDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.model;
      }

      return 'Unknown Device';
    } catch (e) {
      debugPrint('Error getting device model: $e');
      return 'Unknown Device';
    }
  }

  // Get OS version
  Future<String> getOSVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }

      return Platform.operatingSystem;
    } catch (e) {
      debugPrint('Error getting OS version: $e');
      return Platform.operatingSystem;
    }
  }
}