import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/views/screens/home_page.dart';
import 'package:flutterbookstore/views/screens/welcome_page.dart';
import 'package:flutterbookstore/services/auth_service.dart';
import 'package:flutterbookstore/services/cart_service.dart';
import 'package:flutterbookstore/services/paypal_service.dart';
import 'package:flutterbookstore/config/app_config.dart';

// Global key for navigator to handle PayPal returns
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Track previous URL for PayPal return detection
String previousUrl = '';
// Store unique IDs of processed returns to prevent duplicates
Set<String> processedReturnIds = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth service
  await AuthService().init();

  // Initialize PayPal service processed payments
  await PayPalService.initProcessedPayments();

  // Log config settings for debugging
  if (kIsWeb) {
    print('App config:');
    print('API Base URL: ${AppConfig.apiBaseUrl}');
    print('PayPal Return URL: ${AppConfig.paypalReturnUrl}');
    print('PayPal Cancel URL: ${AppConfig.paypalCancelUrl}');

    // Store API configuration in localStorage for the PayPal return page
    try {
      // Store configuration in localStorage for the PayPal return page to use
      html.window.localStorage['apiBaseUrl'] = AppConfig.apiBaseUrl;
      html.window.localStorage['apiKey'] = AppConfig.apiKey;
      print('Stored API config in localStorage');
    } catch (e) {
      print('Error storing API config in localStorage: $e');
    }
  }

  // Initialize cart if user is authenticated
  if (AuthService().isAuthenticated) {
    await CartService.fetchCartItems();
  }

  // Set error handler for missing image assets
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (details.exception is FlutterError) {
      final String message = details.exception.toString();
      if (message.contains('Unable to load asset')) {
        // Return a placeholder for missing images
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.grey),
        );
      }
    }
    return const Center(child: Text('Error'));
  };

  // Setup PayPal return handler for web platform
  if (kIsWeb) {
    // For web platform, we need to handle PayPal returns
    // This is a simplified approach since we're not using js_interop fully
    // In a production app, you would use proper js_interop patterns

    print('Setting up PayPal return handler for web platform');

    // We'll use a more robust approach to detect PayPal returns
    Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        // Check current URL first
        final currentUrl = Uri.base.toString();

        // If we're on a return page, let it handle the redirect
        if (currentUrl.contains('paypal-return.html') ||
            currentUrl.contains('paypal-cancel.html')) {
          print('On PayPal return/cancel page, waiting for redirect');
          return;
        }

        // Extract a unique ID from the URL to track processed returns
        String uniqueReturnId = '';

        // Check URL hash for PayPal parameters (from our custom redirect)
        if (Uri.base.hasFragment) {
          final fragment = Uri.base.fragment;
          if (fragment.contains('paymentId=') &&
              fragment.contains('PayerID=')) {
            print('Found PayPal parameters in URL fragment: $fragment');

            // Extract payment ID as the unique identifier
            final fragmentParams = Uri.parse(
              '?' + fragment.replaceAll('&amp;', '&'),
            );
            final paymentId = fragmentParams.queryParameters['paymentId'];
            if (paymentId != null && paymentId.isNotEmpty) {
              uniqueReturnId = 'fragment_$paymentId';
            }

            // Only process if we haven't seen this return before
            if (uniqueReturnId.isNotEmpty &&
                !processedReturnIds.contains(uniqueReturnId)) {
              processedReturnIds.add(uniqueReturnId);

              // Construct a URL with query parameters instead of fragment
              final processUrl =
                  '${currentUrl.split('#')[0]}?${fragment.replaceAll('&amp;', '&')}';
              PayPalService.handlePayPalReturnUrl(processUrl, navigatorKey);
            }
            return;
          }
        }

        // Check URL query parameters
        if (currentUrl.contains('paymentId=') &&
            currentUrl.contains('PayerID=')) {
          print('Found PayPal parameters in URL: $currentUrl');

          // Extract payment ID as the unique identifier
          final uri = Uri.parse(currentUrl);
          final paymentId = uri.queryParameters['paymentId'];
          if (paymentId != null && paymentId.isNotEmpty) {
            uniqueReturnId = 'query_$paymentId';
          }

          // Only process if we haven't seen this return before
          if (uniqueReturnId.isNotEmpty &&
              !processedReturnIds.contains(uniqueReturnId)) {
            processedReturnIds.add(uniqueReturnId);
            PayPalService.handlePayPalReturnUrl(currentUrl, navigatorKey);
          }
          return;
        }

        // Check if URL changed and contains paypal_return parameter
        if (currentUrl != previousUrl) {
          previousUrl = currentUrl;

          if (currentUrl.contains('paypal_return=true')) {
            // Always consider this fresh - rely on the payment ID tracking for deduplication
            print('Detected PayPal return flag in URL');

            // Extract a unique return ID from the timestamp
            final uri = Uri.parse(currentUrl);
            final timestamp =
                uri.queryParameters['t'] ??
                DateTime.now().millisecondsSinceEpoch.toString();
            uniqueReturnId = 'return_$timestamp';

            // Only process if we haven't seen this return before
            if (!processedReturnIds.contains(uniqueReturnId)) {
              processedReturnIds.add(uniqueReturnId);

              // Check URL hash for PayPal parameters
              if (Uri.base.hasFragment) {
                final fragment = Uri.base.fragment;
                if (fragment.contains('paymentId=') &&
                    fragment.contains('PayerID=')) {
                  print('Found PayPal parameters in URL fragment: $fragment');
                  // Construct a URL with query parameters instead of fragment
                  final processUrl =
                      '${currentUrl.split('#')[0]}?${fragment.replaceAll('&amp;', '&')}';
                  PayPalService.handlePayPalReturnUrl(processUrl, navigatorKey);
                }
              }
            } else {
              print('Skipping already processed return ID: $uniqueReturnId');
            }
          }
        }
      } catch (e) {
        print('Error in PayPal return detection: $e');
      }
    });
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final bool isAuthenticated = AuthService().isAuthenticated;

    return MaterialApp(
      navigatorKey:
          navigatorKey, // Use the global navigator key for PayPal returns
      debugShowCheckedModeBanner: false,
      title: 'Flutter Book Store',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        // Using system fonts instead of custom fonts
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: AppColor.dark,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColor.dark,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColor.dark),
          bodyMedium: TextStyle(color: AppColor.dark),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColor.dark),
          titleTextStyle: TextStyle(
            color: AppColor.dark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: AppColor.primary,
          secondary: AppColor.secondary,
        ),
      ),
      home: isAuthenticated ? const HomePage() : const WelcomePage(),
    );
  }
}
