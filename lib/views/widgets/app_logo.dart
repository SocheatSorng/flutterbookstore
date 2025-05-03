import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, this.height = 30});

  @override
  Widget build(BuildContext context) {
    // Use a different approach for Web vs mobile
    if (kIsWeb) {
      // For web, use a network image with fallback
      return Image.asset(
        'assets/images/logo.png',
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackText();
        },
      );
    } else {
      // For mobile platforms
      return Image.asset(
        'assets/images/logo.png',
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackText();
        },
      );
    }
  }

  Widget _buildFallbackText() {
    return Text(
      'Book Store',
      style: TextStyle(
        color: AppColor.dark,
        fontWeight: FontWeight.w700,
        fontSize: height * 2 / 3,
      ),
    );
  }
}
