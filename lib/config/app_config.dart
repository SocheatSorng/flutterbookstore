class AppConfig {
  // Server configuration
  // Use the correct host and port for your Laravel server
  static String apiHost = '192.168.1.23:8000'; // Laravel standard port is 8000
  static int apiPort = 80; // Standard HTTP port

  // API endpoint - we don't need the port in the URL as it's included in apiHost
  static String get apiBaseUrl => 'http://$apiHost/api';

  // API Key - CRITICAL: This must match the key in your Laravel .env file
  // This is required for all API requests due to api.key middleware
  static const String apiKey =
      'oNm9RNFaejpw0W8MWGtjfPC1tFFJsx7rPVvM5zqPcevnOom86M2RSGcyVmv5';

  // App settings
  static const String appName = 'BookStore';
  static const String appVersion = '1.0.0';

  // Timeout settings
  static const int connectionTimeoutSeconds = 60;
  static const int receiveTimeoutSeconds = 90;

  // Retry settings
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 3;
}
