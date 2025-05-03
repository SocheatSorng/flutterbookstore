import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/views/screens/home_page.dart';
import 'package:flutterbookstore/views/screens/welcome_page.dart';
import 'package:flutterbookstore/services/auth_service.dart';
import 'package:flutterbookstore/services/cart_service.dart';
import 'package:flutterbookstore/services/paypal_service.dart';

// Global key for navigator to handle PayPal returns
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Track previous URL for PayPal return detection
String previousUrl = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth service
  await AuthService().init();

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

        // Check URL hash for PayPal parameters (from our custom redirect)
        if (Uri.base.hasFragment) {
          final fragment = Uri.base.fragment;
          if (fragment.contains('paymentId=') &&
              fragment.contains('PayerID=')) {
            print('Found PayPal parameters in URL fragment: $fragment');
            // Construct a URL with query parameters instead of fragment
            final processUrl =
                '${currentUrl.split('#')[0]}?${fragment.replaceAll('&amp;', '&')}';
            PayPalService.handlePayPalReturnUrl(processUrl, navigatorKey);
            return;
          }
        }

        // Check URL query parameters
        if (currentUrl.contains('paymentId=') &&
            currentUrl.contains('PayerID=')) {
          print('Found PayPal parameters in URL: $currentUrl');
          PayPalService.handlePayPalReturnUrl(currentUrl, navigatorKey);
          return;
        }

        // Check if URL changed and contains paypal_return parameter
        if (currentUrl != previousUrl) {
          previousUrl = currentUrl;
          if (currentUrl.contains('paypal_return=true')) {
            print('Detected PayPal return flag in URL');

            // Check for localStorage data
            // This would be implemented with proper js_interop in a production app
            // For now, we'll use the URL hash approach above
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
