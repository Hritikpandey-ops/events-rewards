import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService = StorageService.instance;

  // State variables
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // Initialize theme from storage
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      final savedTheme = await _storageService.getThemeMode();
      _themeMode = _parseThemeMode(savedTheme);

      notifyListeners();
    } catch (e) {
      // Use default theme if error
      _themeMode = ThemeMode.system;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    try {
      _themeMode = mode;
      notifyListeners();

      // Save to storage
      await _storageService.saveThemeMode(_themeModeToString(mode));
    } catch (e) {
      // Ignore storage errors
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleDarkMode() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  // Set to system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // Set to light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  // Set to dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  // Get theme mode based on system brightness
  ThemeMode getEffectiveThemeMode(Brightness systemBrightness) {
    if (_themeMode == ThemeMode.system) {
      return systemBrightness == Brightness.dark 
          ? ThemeMode.dark 
          : ThemeMode.light;
    }
    return _themeMode;
  }

  // Helper methods
  ThemeMode _parseThemeMode(String themeString) {
    switch (themeString.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
      return 'system';
    }
  }

  // Get theme display name
  String get themeDisplayName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  // Get all available theme options
  List<ThemeModeOption> get availableThemes => [
    const ThemeModeOption(
      mode: ThemeMode.system,
      name: 'System',
      description: 'Follow system theme',
      icon: Icons.settings_system_daydream,
    ),
    const ThemeModeOption(
      mode: ThemeMode.light,
      name: 'Light',
      description: 'Light theme',
      icon: Icons.light_mode,
    ),
    const ThemeModeOption(
      mode: ThemeMode.dark,
      name: 'Dark',
      description: 'Dark theme',
      icon: Icons.dark_mode,
    ),
  ];
}

// Theme mode option class
class ThemeModeOption {
  final ThemeMode mode;
  final String name;
  final String description;
  final IconData icon;

  const ThemeModeOption({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeModeOption && other.mode == mode;
  }

  @override
  int get hashCode => mode.hashCode;
}