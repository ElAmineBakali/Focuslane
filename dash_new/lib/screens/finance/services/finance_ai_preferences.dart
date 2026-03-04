import 'package:shared_preferences/shared_preferences.dart';

class FinanceAiPreferences {
  static const String _autoClassifyKey = 'finance.aiAutoClassifyEnabled';

  static Future<bool> getAutoClassifyEnabled({
    bool fallback = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoClassifyKey) ?? fallback;
  }

  static Future<void> setAutoClassifyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoClassifyKey, enabled);
  }
}
