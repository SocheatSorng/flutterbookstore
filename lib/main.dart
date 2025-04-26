import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/views/screens/home_page.dart';
import 'package:flutterbookstore/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth service
  await AuthService().init();

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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const HomePage(),
    );
  }
}
