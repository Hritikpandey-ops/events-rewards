class AppConstants {
  // App Information
  static const String appName = 'Events & Rewards';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'user_data';
  static const String keyTheme = 'theme_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyNotifications = 'notifications_enabled';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxAudioSize = 50 * 1024 * 1024; // 50MB

  // Camera Settings
  static const double selfieAspectRatio = 1.0; // Square selfie
  static const int selfieQuality = 80;

  // Audio Recording
  static const int maxRecordingDuration = 30; // seconds
  static const int minRecordingDuration = 2; // seconds

  // Pagination
  static const int defaultPageSize = 20;

  // Animation Durations
  static const int shortAnimationDuration = 300;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 1000;

  // Lucky Draw
  static const int wheelSpinDuration = 3000; // ms
  static const int dailySpinLimit = 3;
}