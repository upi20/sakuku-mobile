import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const String _keyPin = 'app_pin';
  static const String _keyPinEnabled = 'app_pin_enabled';

  PinService._();
  static final PinService instance = PinService._();

  // In-memory session flag: true setelah user berhasil input PIN yang benar
  bool _sessionUnlocked = false;

  bool get isSessionUnlocked => _sessionUnlocked;

  void unlockSession() => _sessionUnlocked = true;

  void lockSession() => _sessionUnlocked = false;

  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinEnabled) ?? false;
  }

  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, pin);
    await prefs.setBool(_keyPinEnabled, true);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPin);
    await prefs.setBool(_keyPinEnabled, false);
  }

  Future<bool> checkPin(String input) async {
    final stored = await getPin();
    return stored != null && stored == input;
  }

  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPinEnabled, enabled);
  }
}
