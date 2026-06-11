import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 1. Key: Nama User (Default: Sunghoon)
  static String get userName => _prefs.getString('user_name') ?? 'Sunghoon';
  static Future<void> setUserName(String value) async => await _prefs.setString('user_name', value);

  // 2. Key: Sensor Saldo (Default: false)
  static bool get isBalanceHidden => _prefs.getBool('is_balance_hidden') ?? false;
  static Future<void> setBalanceHidden(bool value) async => await _prefs.setBool('is_balance_hidden', value);

  // 3. Key: Theme Mode
  static bool get isDarkMode => _prefs.getBool('theme_mode') ?? false;
  static Future<void> setDarkMode(bool value) async => await _prefs.setBool('theme_mode', value);

  // 4. Key: User Role (Default: Ketuplak)
  static String get userRole => _prefs.getString('user_role') ?? 'Ketuplak';
  static Future<void> setUserRole(String value) async => await _prefs.setString('user_role', value);

  // 5. Key: User Profile Photo Path
  static String get userProfilePhoto => _prefs.getString('user_profile_photo') ?? '';
  static Future<void> setUserProfilePhoto(String value) async => await _prefs.setString('user_profile_photo', value);
  static Future<void> deleteUserProfilePhoto() async => await _prefs.remove('user_profile_photo');
}