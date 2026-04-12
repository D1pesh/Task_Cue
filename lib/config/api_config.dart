// API Configuration for TaskCue Application
//
// This file contains all API configuration settings and endpoints.
// Update these values to match your backend deployment.

class ApiConfig {
  // Backend Base URL - UPDATE THIS FOR YOUR DEPLOYMENT
  // Development: http://localhost:8000
  // Staging: https://staging.taskcue.com
  // Production: https://api.taskcue.com
  static const String backendBaseUrl = 'http://localhost:8000';

  // Gamification API Endpoints
  static const String leaderboardEndpoint = '/api/v1/gamification/leaderboard/';
  static const String pointsEndpoint = '/api/v1/gamification/points/';
  static const String achievementsEndpoint = '/api/v1/gamification/achievements/';
  static const String awardPointsEndpoint = '/api/v1/gamification/award-points/';

  // User API Endpoints
  static const String userProfileEndpoint = '/api/v1/auth/me/';
  static const String updateProfileEndpoint = '/api/v1/auth/profile/update/';

  // Tasks API Endpoints
  static const String tasksEndpoint = '/api/v1/tasks/';
  static const String createTaskEndpoint = '/api/v1/tasks/create/';
  static const String updateTaskEndpoint = '/api/v1/tasks/{id}/';
  static const String completeTaskEndpoint = '/api/v1/tasks/{id}/complete/';

  // Full URLs
  static String get leaderboardUrl => backendBaseUrl + leaderboardEndpoint;
  static String get pointsUrl => backendBaseUrl + pointsEndpoint;
  static String get achievementsUrl => backendBaseUrl + achievementsEndpoint;
  static String get awardPointsUrl => backendBaseUrl + awardPointsEndpoint;
  static String get userProfileUrl => backendBaseUrl + userProfileEndpoint;
  static String get updateProfileUrl => backendBaseUrl + updateProfileEndpoint;
  static String get tasksUrl => backendBaseUrl + tasksEndpoint;

  // API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Leaderboard Configuration
  static const int leaderboardLimitTop = 50;
  static const int leaderboardRefreshInterval = 30; // seconds
  static const Map<int, String> medalTypes = {
    1: 'gold',
    2: 'silver',
    3: 'bronze',
  };

  // Network Configuration
  static const bool useSSL = true;
  static const bool validateSSLCertificate = true;

  /// Get medal type by rank
  static String? getMedalType(int rank) {
    return medalTypes[rank];
  }

  /// Check if running in debug mode
  static const bool isDebugMode = true; // Set to false in production

  /// Get full endpoint URL with parameters
  static String buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    final url = backendBaseUrl + endpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      return '$url?$query';
    }
    return url;
  }
}

/// Environment-specific configuration
class EnvironmentConfig {
  static const String environment = 'development'; // development, staging, production

  static const Map<String, String> environmentUrls = {
    'development': 'http://localhost:8000',
    'staging': 'https://staging-api.taskcue.com',
    'production': 'https://api.taskcue.com',
  };

  static String getBackendUrl() {
    return environmentUrls[environment] ?? ApiConfig.backendBaseUrl;
  }
}
