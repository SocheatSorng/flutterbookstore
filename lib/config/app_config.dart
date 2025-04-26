class AppConfig {
  // Server configuration
  // Updated to use the remote server instead of local IP
  static String apiHost = '18.140.63.109'; // Remote server IP
  static int apiPort = 80; // Standard HTTP port

  // API endpoint - we don't need the port in the URL as it's standard HTTP port 80
  static String get apiBaseUrl => 'http://$apiHost/api';

  // App settings
  static const String appName = 'BookStore';
  static const String appVersion = '1.0.0';
  
  // Timeout settings - increased significantly to handle slower connections
  static const int connectionTimeoutSeconds = 60; // Increased from 30
  static const int receiveTimeoutSeconds = 90; // Increased from 60
  
  // Retry settings
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 3; // Increased delay to let server recover
} 