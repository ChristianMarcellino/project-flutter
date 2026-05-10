import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setBool("darkMode", true);
  }

  static Future<void> setDarkMode(bool value) async {
    await prefs.setBool('darkMode', value);
  }

  static bool get isDarkMode => prefs.getBool('isDarkMode') ?? false;
}
