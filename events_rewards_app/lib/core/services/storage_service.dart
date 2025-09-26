import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  // Authentication related storage
  Future<void> saveAuthToken(String token) async {
    await prefs.setString('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return prefs.getString('auth_token');
  }

  Future<void> clearAuthToken() async {
    await prefs.remove('auth_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await prefs.setString('refresh_token', token);
  }

  Future<String?> getRefreshToken() async {
    return prefs.getString('refresh_token');
  }

  Future<void> clearRefreshToken() async {
    await prefs.remove('refresh_token');
  }

  // User data storage
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await prefs.setString('user_data', jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(userDataString));
      } catch (e) {
        // Handle JSON decode error
        return null;
      }
    }
    return null;
  }

  Future<void> clearUserData() async {
    await prefs.remove('user_data');
  }

  // Theme storage - FIXED TYPE ISSUE
  Future<void> saveThemeMode(String themeMode) async {
    await prefs.setString('theme_mode', themeMode);
  }

  Future<String> getThemeMode() async {
    // Fixed: Proper type handling with null safety
    return prefs.getString('theme_mode') ?? 'system';
  }

  // Language storage
  Future<void> saveLanguage(String languageCode) async {
    await prefs.setString('language_code', languageCode);
  }

  Future<String> getLanguage() async {
    return prefs.getString('language_code') ?? 'en';
  }

  // Device info storage
  Future<void> saveDeviceInfo(Map<String, dynamic> deviceInfo) async {
    await prefs.setString('device_info', jsonEncode(deviceInfo));
  }

  Future<Map<String, dynamic>?> getDeviceInfo() async {
    final deviceInfoString = prefs.getString('device_info');
    if (deviceInfoString != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(deviceInfoString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Location storage
  Future<void> saveLastKnownLocation(Map<String, dynamic> location) async {
    await prefs.setString('last_location', jsonEncode(location));
  }

  Future<Map<String, dynamic>?> getLastKnownLocation() async {
    final locationString = prefs.getString('last_location');
    if (locationString != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(locationString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // App settings
  Future<void> saveNotificationSettings(bool enabled) async {
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<bool> getNotificationSettings() async {
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await prefs.setBool('biometric_enabled', enabled);
  }

  Future<bool> getBiometricEnabled() async {
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // Onboarding and first launch
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await prefs.setBool('is_first_launch', isFirstLaunch);
  }

  Future<bool> isFirstLaunch() async {
    return prefs.getBool('is_first_launch') ?? true;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await prefs.setBool('onboarding_completed', completed);
  }

  Future<bool> isOnboardingCompleted() async {
    return prefs.getBool('onboarding_completed') ?? false;
  }

  // Cache management
  Future<void> saveCacheData(String key, Map<String, dynamic> data, {Duration? expiry}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await prefs.setString('cache_$key', jsonEncode(cacheData));
  }

  Future<Map<String, dynamic>?> getCacheData(String key) async {
    final cacheString = prefs.getString('cache_$key');
    if (cacheString != null) {
      try {
        final cacheData = jsonDecode(cacheString);
        final timestamp = cacheData['timestamp'] as int;
        final expiry = cacheData['expiry'] as int?;

        // Check if cache has expired
        if (expiry != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp).add(Duration(milliseconds: expiry));
          if (DateTime.now().isAfter(expiryTime)) {
            // Cache expired, remove it
            await clearCacheData(key);
            return null;
          }
        }

        return Map<String, dynamic>.from(cacheData['data']);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearCacheData(String key) async {
    await prefs.remove('cache_$key');
  }

  // Events cache
  Future<void> saveEventsCache(List<Map<String, dynamic>> events) async {
    await saveCacheData('events', {'events': events}, expiry: const Duration(minutes: 30));
  }

  Future<List<Map<String, dynamic>>?> getEventsCache() async {
    final cacheData = await getCacheData('events');
    if (cacheData != null && cacheData.containsKey('events')) {
      return List<Map<String, dynamic>>.from(cacheData['events']);
    }
    return null;
  }

  // News cache
  Future<void> saveNewsCache(List<Map<String, dynamic>> news) async {
    await saveCacheData('news', {'news': news}, expiry: const Duration(minutes: 15));
  }

  Future<List<Map<String, dynamic>>?> getNewsCache() async {
    final cacheData = await getCacheData('news');
    if (cacheData != null && cacheData.containsKey('news')) {
      return List<Map<String, dynamic>>.from(cacheData['news']);
    }
    return null;
  }

  // Home config cache
  Future<void> saveHomeConfigCache(Map<String, dynamic> config) async {
    await saveCacheData('home_config', config, expiry: const Duration(hours: 1));
  }

  Future<Map<String, dynamic>?> getHomeConfigCache() async {
    return await getCacheData('home_config');
  }

  // Search history
  Future<void> saveSearchHistory(List<String> searchTerms) async {
    // Keep only last 20 search terms
    final limitedTerms = searchTerms.take(20).toList();
    await prefs.setStringList('search_history', limitedTerms);
  }

  Future<List<String>> getSearchHistory() async {
    return prefs.getStringList('search_history') ?? [];
  }

  Future<void> addToSearchHistory(String term) async {
    final history = await getSearchHistory();

    // Remove if already exists to avoid duplicates
    history.remove(term);

    // Add to beginning
    history.insert(0, term);

    await saveSearchHistory(history);
  }

  Future<void> clearSearchHistory() async {
    await prefs.remove('search_history');
  }

  // Favorites
  Future<void> saveFavoriteEvents(List<String> eventIds) async {
    await prefs.setStringList('favorite_events', eventIds);
  }

  Future<List<String>> getFavoriteEvents() async {
    return prefs.getStringList('favorite_events') ?? [];
  }

  Future<void> addToFavoriteEvents(String eventId) async {
    final favorites = await getFavoriteEvents();
    if (!favorites.contains(eventId)) {
      favorites.add(eventId);
      await saveFavoriteEvents(favorites);
    }
  }

  Future<void> removeFromFavoriteEvents(String eventId) async {
    final favorites = await getFavoriteEvents();
    favorites.remove(eventId);
    await saveFavoriteEvents(favorites);
  }

  Future<bool> isEventFavorite(String eventId) async {
    final favorites = await getFavoriteEvents();
    return favorites.contains(eventId);
  }

  // Bookmarked news
  Future<void> saveBookmarkedNews(List<String> newsIds) async {
    await prefs.setStringList('bookmarked_news', newsIds);
  }

  Future<List<String>> getBookmarkedNews() async {
    return prefs.getStringList('bookmarked_news') ?? [];
  }

  Future<void> addToBookmarkedNews(String newsId) async {
    final bookmarks = await getBookmarkedNews();
    if (!bookmarks.contains(newsId)) {
      bookmarks.add(newsId);
      await saveBookmarkedNews(bookmarks);
    }
  }

  Future<void> removeFromBookmarkedNews(String newsId) async {
    final bookmarks = await getBookmarkedNews();
    bookmarks.remove(newsId);
    await saveBookmarkedNews(bookmarks);
  }

  Future<bool> isNewsBookmarked(String newsId) async {
    final bookmarks = await getBookmarkedNews();
    return bookmarks.contains(newsId);
  }

  // Lucky draw data
  Future<void> saveLastSpinDate(DateTime date) async {
    await prefs.setInt('last_spin_date', date.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSpinDate() async {
    final timestamp = prefs.getInt('last_spin_date');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> saveSpinsRemaining(int spins) async {
    await prefs.setInt('spins_remaining', spins);
  }

  Future<int> getSpinsRemaining() async {
    return prefs.getInt('spins_remaining') ?? 3; // Default 3 spins per day
  }

  // App version tracking
  Future<void> saveAppVersion(String version) async {
    await prefs.setString('app_version', version);
  }

  Future<String?> getAppVersion() async {
    return prefs.getString('app_version');
  }

  // Clear all data (for logout)
  Future<void> clearAllUserData() async {
    final keys = prefs.getKeys().where((key) => 
      key.startsWith('auth_') || 
      key.startsWith('user_') ||
      key.startsWith('cache_') ||
      key == 'search_history' ||
      key == 'favorite_events' ||
      key == 'bookmarked_news' ||
      key == 'last_spin_date' ||
      key == 'spins_remaining'
    ).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // Clear only cache data
  Future<void> clearAllCache() async {
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // Debug: Get all stored keys
  Set<String> getAllKeys() {
    return prefs.getKeys();
  }

  // Debug: Get storage size (approximate)
  Future<int> getStorageSize() async {
    int totalSize = 0;
    final keys = prefs.getKeys();

    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        totalSize += key.length + value.toString().length;
      }
    }

    return totalSize;
  }
}