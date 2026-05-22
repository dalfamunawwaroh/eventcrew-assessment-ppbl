import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 1. Key: Nama User (Default: Sunghoon)
  static String get userName => _prefs.getString('user_name') ?? 'Sunghoon';
  static Future<void> setUserName(String value) async => await _prefs.setString('user_name', value);

  // 2. Key: First Time
  static bool get isFirstTime => _prefs.getBool('is_first_time') ?? true;
  static Future<void> setFirstTime(bool value) async => await _prefs.setBool('is_first_time', value);

  // 3. Key: Theme Mode
  static bool get isDarkMode => _prefs.getBool('theme_mode') ?? false;
  static Future<void> setDarkMode(bool value) async => await _prefs.setBool('theme_mode', value);

  // 4. Key: User Role
  static String get userRole => _prefs.getString('user_role') ?? 'Ketuplak';
  static Future<void> setUserRole(String value) async => await _prefs.setString('user_role', value);
}