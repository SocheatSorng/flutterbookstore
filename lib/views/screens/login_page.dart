import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/services/auth_service.dart';
import 'package:flutterbookstore/views/screens/home_page.dart';
import 'package:flutterbookstore/views/screens/register_page.dart';
import 'package:flutterbookstore/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColor.dark),
        title: Text(
          'Sign In (Optional)',
          style: TextStyle(color: AppColor.dark, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            // Optional login message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColor.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'You can continue shopping without an account. Creating an account helps you track orders and save favorites.',
                      style: TextStyle(
                        color: AppColor.dark,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Welcome Back 👋',
              style: TextStyle(
                color: AppColor.dark,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login with the username/email and password created in your account',
              style: TextStyle(
                color: AppColor.grey,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            // Email Field
            _buildTextField(
              controller: _emailController,
              hintText: 'Email or Username',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            // Password Field
            _buildTextField(
              controller: _passwordController,
              hintText: 'Password',
              isPassword: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 8),
            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColor.primary),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Login Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_emailController.text.isEmpty ||
                      _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both email and password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Show loading indicator
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final success = await AuthService().login(
                      _emailController.text,
                      _passwordController.text,
                    );

                    if (success) {
                      // Navigate to home page
                      if (!mounted) return;

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } else {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Invalid email or password. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            // Continue as Guest Button
            SizedBox(
              height: 50,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.dark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColor.border),
                  ),
                ),
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Or Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColor.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColor.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColor.border, thickness: 1)),
              ],
            ),
            const SizedBox(height: 24),
            // Debug button for testing API connectivity (remove in production)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    setState(() {
                      _isLoading = true;
                    });

                    // Test API connectivity
                    final response = await http.get(
                      Uri.parse('${AppConfig.apiBaseUrl}'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                      },
                    );

                    String message = 'API Connection Test:\n';
                    message += 'Status code: ${response.statusCode}\n';
                    message += 'API URL: ${AppConfig.apiBaseUrl}\n';

                    if (response.statusCode >= 200 &&
                        response.statusCode < 400) {
                      message += 'Connection successful!\n';
                      try {
                        final data = json.decode(response.body);
                        if (data is Map) {
                          message += 'API data: ${data.keys}\n';
                        }
                      } catch (e) {
                        message += 'Could not parse response as JSON\n';
                      }
                    } else {
                      message += 'Connection failed.\n';
                    }

                    // Try an OPTIONS request to check CORS configuration
                    try {
                      final optionsResponse = await http.get(
                        Uri.parse('${AppConfig.apiBaseUrl}/login'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Accept': 'application/json',
                        },
                      );

                      message += '\nOPTIONS check for login endpoint:\n';
                      message += 'Status: ${optionsResponse.statusCode}\n';

                      // Check if server provides CORS headers
                      if (optionsResponse.headers.containsKey(
                        'access-control-allow-origin',
                      )) {
                        message += 'CORS enabled: Yes\n';
                        message +=
                            'Allowed origins: ${optionsResponse.headers['access-control-allow-origin']}\n';
                      } else {
                        message += 'CORS headers not found\n';
                      }
                    } catch (e) {
                      message += '\nOPTIONS request failed: $e';
                    }

                    message +=
                        '\nResponse preview: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 15),
                        action: SnackBarAction(
                          label: 'OK',
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );

                    // Additionally log to console for more detail
                    print('====== API TEST DETAILS ======');
                    print(message);
                    print('Full response body: ${response.body}');
                    print('Response headers: ${response.headers}');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 10),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('Test API Connection'),
              ),
            ),
            // Debug button for testing credentials (remove in production)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    if (_emailController.text.isEmpty ||
                        _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter credentials to test'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    // Test the login API directly with raw http request
                    final loginUrl = '${AppConfig.apiBaseUrl}/login';
                    final response = await http.post(
                      Uri.parse(loginUrl),
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                      },
                      body: json.encode({
                        'email': _emailController.text,
                        'password': _passwordController.text,
                      }),
                    );

                    String message = 'Direct Login Test:\n';
                    message += 'Status code: ${response.statusCode}\n';
                    message +=
                        'Response: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}\n';

                    // Also try form-encoded version
                    final formResponse = await http.post(
                      Uri.parse(loginUrl),
                      headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Accept': 'application/json',
                      },
                      body:
                          'email=${Uri.encodeComponent(_emailController.text)}&password=${Uri.encodeComponent(_passwordController.text)}',
                    );

                    message += '\nForm-encoded test:\n';
                    message += 'Status code: ${formResponse.statusCode}\n';
                    message +=
                        'Response: ${formResponse.body.length > 200 ? formResponse.body.substring(0, 200) + '...' : formResponse.body}';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 15),
                        action: SnackBarAction(
                          label: 'OK',
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );

                    // Log to console
                    print('====== DIRECT LOGIN TEST ======');
                    print(message);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 10),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('Test Credentials'),
              ),
            ),
            // Register Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account?',
                  style: TextStyle(color: AppColor.grey),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary,
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColor.dark),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColor.lightGrey,
        hintText: hintText,
        hintStyle: TextStyle(color: AppColor.grey),
        prefixIcon: Icon(prefixIcon, color: AppColor.grey),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColor.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
