import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Server configuration
  // Use the correct host and port for your Laravel server
  static String apiHost = '3.1.206.22'; // Laravel standard port is 8000
  static int apiPort = 80; // Standard HTTP port

  // API endpoint - we don't need the port in the URL as it's included in apiHost
  static String get apiBaseUrl => 'http://$apiHost/api';

  // API Key - CRITICAL: This must match the key in your Laravel .env file
  // This is required for all API requests due to api.key middleware
  static const String apiKey =
      '3EaR78ULtCRLyykSeCENE7E3WStGHqKrFiSppycQwcNj2cLvolcknKemzjnO';

  // App settings
  static const String appName = 'BookStore';
  static const String appVersion = '1.0.0';

  // Timeout settings
  static const int connectionTimeoutSeconds = 60;
  static const int receiveTimeoutSeconds = 90;

  // Retry settings
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 3;

  // PayPal Configuration
  // Replace these with your actual PayPal credentials
  static const bool paypalSandboxMode = true; // Set to false for production
  static const String paypalClientId =
      'AZvsEK-9Ib238XTeZZEdTeDhQJOzEp6jiQzUpOHSPwB7-RyhwxaoRzeMfR3oymHJL5caroDXHICjC9FY';
  static const String paypalClientSecret =
      'EJJTPM7c9reKnDWuG0peNoHDA-y9f1rgd-uE_JsJOhHVLNFf0xrRXsuFK6DSLcJfGVRft7VJd19Pky6u';

  // PayPal return and cancel URLs
  // For web platform, use a regular URL that can be handled by the browser
  // For mobile/desktop, use custom URL scheme
  static String get paypalReturnUrl =>
      kIsWeb
          ? 'http://${Uri.base.host}:${Uri.base.port}/paypal-return.html'
          : 'flutterbookstore://paypalpay';

  static String get paypalCancelUrl =>
      kIsWeb
          ? 'http://${Uri.base.host}:${Uri.base.port}/paypal-cancel.html'
          : 'flutterbookstore://cancel';

  // Currency
  static const String currency = 'USD';
}
