import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the native Android check for the "Developer options" master
/// toggle (Settings.Global.DEVELOPMENT_SETTINGS_ENABLED).
///
/// Used as an anti-tampering gate: attendance apps are a common target for
/// mock-location / debugging tools, so the app refuses to run while Developer
/// options is enabled. The check fails open (returns false) on any error or on
/// non-Android platforms so a platform quirk can never permanently brick the
/// app.
class DeviceSecurity {
  DeviceSecurity._();

  static const MethodChannel _channel =
      MethodChannel('lumenor/device_security');

  static Future<bool> isDeveloperOptionsEnabled() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final enabled =
          await _channel.invokeMethod<bool>('isDeveloperOptionsEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }
}
