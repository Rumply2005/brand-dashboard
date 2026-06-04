import 'package:shared_preferences/shared_preferences.dart';

/// Repository that manages brand profile preferences.
/// Uses SharedPreferences for lightweight key-value storage.
class ProfileRepository {
  static const _keyBrandName = 'brand_name';
  static const _keyAccentColor = 'accent_color';
  static const _keyLogoPath = 'logo_path';

  Future<String> getBrandName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBrandName) ?? 'Mi Marca';
  }

  Future<int> getAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAccentColor) ?? 0xFFB8860B;
  }

  Future<String?> getLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLogoPath);
  }

  Future<void> saveBrandName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBrandName, name);
  }

  Future<void> saveAccentColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, colorValue);
  }

  Future<void> saveLogoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLogoPath, path);
  }
}