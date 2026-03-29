import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);

    // Update system UI overlay style
    _updateSystemUIOverlay();
  }

  void _updateSystemUIOverlay() {
    final brightness = _themeMode == ThemeMode.dark
        ? Brightness.dark
        : _themeMode == ThemeMode.light
            ? Brightness.light
            : WidgetsBinding.instance.platformDispatcher.platformBrightness;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> toggleTheme() async {
    final newTheme =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newTheme);
  }
}
