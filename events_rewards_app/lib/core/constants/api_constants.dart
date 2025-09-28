class ApiConstants {
  // Base URL - Update this to match your GoLang backend
  static const String baseUrl = 'http://localhost:8080/api/v1'; 

  // Timeout constants
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  static const int sendTimeout = 30; // seconds

  // API Endpoints

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String uploadSelfie = '/user/upload-selfie';
  static const String uploadVoice = '/user/upload-voice';
  static const String verifyIdentity = '/user/verify-identity';
  static const String deviceInfo = '/user/device-info';
  static const String location = '/user/location';

  // Events endpoints
  static const String events = '/events';
  static const String userEvents = '/user/events';
  static String eventDetails(String id) => '/events/$id';
  static String registerEvent(String id) => '/events/$id/register';
  static String unregisterEvent(String id) => '/events/$id/unregister';

  // News endpoints
  static const String news = '/news';
  static String newsDetails(String id) => '/news/$id';
  static const String newsCategories = '/news/categories';

  // Lucky draw endpoints
  static const String luckyDrawConfig = '/lucky-draw/config';
  static const String spinWheel = '/lucky-draw/spin';
  static const String userSpins = '/lucky-draw/user-spins';

  // Rewards endpoints
  static const String rewards = '/rewards';
  static const String userRewards = "/lucky-draw/my-rewards"; 
  static String claimReward(String id) => '/rewards/$id/claim';
  static String rewardDetails(String id) => '/rewards/$id';

  // Configuration endpoints
  static const String uiConfig = '/config/ui';
  static const String appConfig = '/config/app';
  static const String healthCheck = '/health';

  // File upload endpoints
  static const String uploadImage = '/upload/image';
  static const String uploadAudio = '/upload/audio';
  static const String uploadFile = '/upload/file';

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int defaultPage = 1;

  // Request headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Map<String, String> multipartHeaders = {
    'Content-Type': 'multipart/form-data',
    'Accept': 'application/json',
  };

  // Cache durations (in minutes)
  static const int shortCacheDuration = 5; // 5 minutes
  static const int mediumCacheDuration = 30; // 30 minutes
  static const int longCacheDuration = 60; // 1 hour
  static const int extraLongCacheDuration = 1440; // 24 hours

  // File upload limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxAudioSize = 10 * 1024 * 1024; // 10MB
  static const int maxFileSize = 20 * 1024 * 1024; // 20MB

  // Allowed file types
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/webp',
  ];

  static const List<String> allowedAudioTypes = [
    'audio/mp3',
    'audio/wav',
    'audio/m4a',
    'audio/aac',
    'audio/ogg',
  ];

  // API Response status codes
  static const int statusSuccess = 200;
  static const int statusCreated = 201;
  static const int statusAccepted = 202;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusMethodNotAllowed = 405;
  static const int statusConflict = 409;
  static const int statusUnprocessableEntity = 422;
  static const int statusTooManyRequests = 429;
  static const int statusInternalServerError = 500;
  static const int statusBadGateway = 502;
  static const int statusServiceUnavailable = 503;
  static const int statusGatewayTimeout = 504;

  // Error messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error occurred. Please try again later.';
  static const String unauthorizedError = 'Session expired. Please login again.';
  static const String forbiddenError = 'You do not have permission to perform this action.';
  static const String notFoundError = 'Requested resource not found.';
  static const String validationError = 'Please check your input and try again.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String unknownError = 'An unexpected error occurred.';

  // Environment-specific URLs
  static const String developmentBaseUrl = 'http://localhost:8080/api/v1';
  static const String stagingBaseUrl = 'https://staging-api.yourapp.com/api/v1';
  static const String productionBaseUrl = 'https://api.yourapp.com/api/v1';

  // Get base URL based on environment
  static String getBaseUrl() {
    // In a real app, this would check build configuration or environment variables
    const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

    switch (environment) {
      case 'production':
        return productionBaseUrl;
      case 'staging':
        return stagingBaseUrl;
      case 'development':
      default:
        return developmentBaseUrl;
    }
  }

  // API versioning
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api';

  // Authentication
  static const String bearerPrefix = 'Bearer ';
  static const String authHeaderKey = 'Authorization';
  static const String refreshTokenKey = 'refresh_token';
  static const String accessTokenKey = 'access_token';

  // Query parameter keys
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const String searchParam = 'search';
  static const String categoryParam = 'category';
  static const String locationParam = 'location';
  static const String sortParam = 'sort';
  static const String orderParam = 'order';
  static const String filterParam = 'filter';

  // Lucky draw configuration
  static const int maxSpinsPerDay = 3;
  static const int spinCooldownHours = 8;

  // Event configuration
  static const int maxEventRegistrations = 10;
  static const int eventRegistrationTimeoutMinutes = 15;

  // Validation constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 1000;

  // Regular expressions for validation
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[\d\s\-\(\)]{10,15}$';
  static const String nameRegex = r'^[a-zA-Z\s]{2,50}$';

  // Date/Time formats
  static const String apiDateFormat = 'yyyy-MM-ddTHH:mm:ss.SSSZ';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayTimeFormat = 'HH:mm';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
  static const List<int> retryStatusCodes = [
    statusTooManyRequests,
    statusInternalServerError,
    statusBadGateway,
    statusServiceUnavailable,
    statusGatewayTimeout,
  ];

  // Debug settings
  static const bool enableLogging = true;
  static const bool enableDetailedLogging = false;
  static const bool enableNetworkLogging = true;

  // Feature flags (for dynamic feature toggling)
  static const String featureLuckyDraw = 'lucky_draw_enabled';
  static const String featureEvents = 'events_enabled';
  static const String featureNews = 'news_enabled';
  static const String featureRewards = 'rewards_enabled';
  static const String featureIdentityVerification = 'identity_verification_enabled';

  // Storage keys (for local storage)
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String deviceInfoKey = 'device_info';
  static const String locationDataKey = 'location_data';
}

// Environment configuration helper
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  static String get current {
    return const String.fromEnvironment('ENVIRONMENT', defaultValue: development);
  }

  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;

  static String get baseUrl {
    switch (current) {
      case production:
        return ApiConstants.productionBaseUrl;
      case staging:
        return ApiConstants.stagingBaseUrl;
      default:
        return ApiConstants.developmentBaseUrl;
    }
  }
}