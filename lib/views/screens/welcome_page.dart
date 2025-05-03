import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
import 'package:flutterbookstore/views/screens/register_page.dart';
import 'package:flutterbookstore/views/screens/home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Logo and branding with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: MediaQuery.of(context).size.width * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.primary.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 10,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 80,
                                  color: AppColor.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Book Store App',
                                style: TextStyle(
                                  color: AppColor.dark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Version 1.0',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // App title and description with slide animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Books ',
                                    style: TextStyle(
                                      color: AppColor.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'for Everyone',
                                    style: TextStyle(
                                      color: AppColor.dark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.lightGrey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColor.primary.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Discover thousands of books and start your reading journey today. Get personalized recommendations and track your reading progress.',
                                style: TextStyle(
                                  color: AppColor.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                    // Action buttons with animations
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => const LoginPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColor.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        shadowColor: AppColor.primary
                                            .withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.login_rounded, size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const RegisterPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColor.primary,
                                        elevation: 0,
                                        side: BorderSide(
                                          color: AppColor.primary,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.person_add_outlined,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Register',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: 60,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const HomePage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColor.dark.withOpacity(
                                    0.7,
                                  ),
                                  padding: const EdgeInsets.all(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.grey.withOpacity(
                                    0.05,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.arrow_forward, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Continue as Guest',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'By continuing, you agree to our Terms of Service and Privacy Policy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.grey,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
