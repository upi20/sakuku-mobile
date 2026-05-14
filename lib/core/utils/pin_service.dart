import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const String _keyPin = 'app_pin';
  static const String _keyPinEnabled = 'app_pin_enabled';

  PinService._();
  static final PinService instance = PinService._();

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
