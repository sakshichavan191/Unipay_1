import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local PIN storage service using flutter_secure_storage.
/// No backend calls — everything stays on-device.
class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'unipay_app_pin';
  static const _pinEnabledKey = 'unipay_pin_enabled';

  /// Check if PIN lock is enabled
  static Future<bool> isPinEnabled() async {
    final val = await _storage.read(key: _pinEnabledKey);
    return val == 'true';
  }

  /// Get the stored PIN (null if not set)
  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  /// Save a new PIN and enable lock
  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  /// Verify input against stored PIN
  static Future<bool> verifyPin(String input) async {
    final stored = await _storage.read(key: _pinKey);
    return stored == input;
  }

  /// Disable PIN lock and clear stored PIN
  static Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }
}
