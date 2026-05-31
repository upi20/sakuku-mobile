import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan dan membaca Gemini API key milik pengguna.
/// Pola singleton identik dengan [PinService].
class AiKeyService {
  static const String _keyApiKey = 'gemini_api_key';

  AiKeyService._();
  static final AiKeyService instance = AiKeyService._();

  Future<String?> getKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<void> setKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key.trim());
  }

  Future<void> removeKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
  }

  Future<bool> hasKey() async {
    final key = await getKey();
    return key != null && key.isNotEmpty;
  }
}
