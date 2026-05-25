import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

const _themePrefsKey = 'app_theme_mode';

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePrefsKey);
    if (savedTheme != null) {
      final mode = AppThemeMode.values.firstWhere(
        (m) => m.name == savedTheme,
        orElse: () => AppThemeMode.system,
      );
      if (mounted) {
        state = mode;
      }
    }
  }

  Future<void> _saveTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefsKey, mode.name);
  }

  void toggleTheme() {
    // Cycle through: light → dark → system → light
    late AppThemeMode next;
    switch (state) {
      case AppThemeMode.light:
        next = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        next = AppThemeMode.system;
        break;
      case AppThemeMode.system:
        next = AppThemeMode.light;
        break;
    }
    state = next;
    _saveTheme(next);
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
    _saveTheme(mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
