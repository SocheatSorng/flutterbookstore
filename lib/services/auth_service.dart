import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterbookstore/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Authentication state
  bool _isAuthenticated = false;
  String? _authToken;
  Map<String, dynamic>? _currentUser;

  // CSRF token for Laravel protection
  String? _csrfToken;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Headers with API key for unauthenticated requests
  Map<String, String> get apiKeyHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // The X-API-Key header is required by your Laravel backend middleware
    'X-API-Key': AppConfig.apiKey,
  };

  // Headers with both API key and authentication token for authenticated requests
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': AppConfig.apiKey,
    'Authorization': 'Bearer $_authToken',
  };

  // Get request headers with CSRF token if available
  Map<String, String> get csrfHeaders {
    final headers = Map<String, String>.from(apiKeyHeaders);
    if (_csrfToken != null) {
      headers['X-XSRF-TOKEN'] = _csrfToken!;
    }
    return headers;
  }

  // Initialize authentication state from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    final userJson = prefs.getString('current_user');

    if (_authToken != null && userJson != null) {
      _isAuthenticated = true;
      _currentUser = json.decode(userJson);
      print('User authenticated with token: $_authToken');
      print('Current user: $_currentUser');
    } else {
      print('No authentication found in storage');
    }

    // Try to get CSRF token
    await _fetchCsrfToken();
  }

  // Fetch CSRF token from Laravel
  Future<void> _fetchCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/sanctum/csrf-cookie'),
        headers: {'Accept': 'application/json'},
      );

      print('CSRF token request status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // CSRF token is usually in the cookies
        if (response.headers.containsKey('set-cookie')) {
          final cookies = response.headers['set-cookie']!;
          print('Cookies received: $cookies');

          // Extract XSRF-TOKEN from cookies
          final xsrfCookie = cookies
              .split(';')
              .firstWhere(
                (cookie) => cookie.trim().startsWith('XSRF-TOKEN='),
                orElse: () => '',
              );

          if (xsrfCookie.isNotEmpty) {
            _csrfToken = Uri.decodeComponent(xsrfCookie.split('=')[1].trim());
            print('CSRF Token obtained: $_csrfToken');
          }
        }
      }
    } catch (e) {
      print('Error fetching CSRF token: $e');
    }
  }

  // Login function
  Future<bool> login(String email, String password) async {
    try {
      // Based on the API routes, we should use customer/login endpoint
      final loginUrl = '${AppConfig.apiBaseUrl}/customer/login';

      // Check if input is an email
      final bool isEmail = email.contains('@') && email.contains('.');

      // Modified to match the Laravel backend field expectations
      final loginData =
          isEmail
              ? {'email': email, 'password': password}
              : {'username': email, 'password': password};

      print('====== LOGIN REQUEST ======');
      print('URL: $loginUrl');
      print('Headers: ${apiKeyHeaders}');
      print('Body: ${json.encode(loginData)}');

      // Use apiKeyHeaders for initial request
      var response = await http.post(
        Uri.parse(loginUrl),
        headers: apiKeyHeaders,
        body: json.encode(loginData),
      );

      // If first attempt fails, try with form-encoded data
      if (response.statusCode == 401) {
        print('Trying form-encoded approach...');

        // Create headers with API key for form submission
        final formHeaders = {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-API-Key': AppConfig.apiKey,
        };

        // Only include the username or email field based on input format
        String formBody =
            isEmail
                ? 'email=${Uri.encodeComponent(email)}'
                : 'username=${Uri.encodeComponent(email)}';
        formBody += '&password=${Uri.encodeComponent(password)}';

        response = await http.post(
          Uri.parse(loginUrl),
          headers: formHeaders,
          body: formBody,
        );
      }

      print('====== LOGIN RESPONSE ======');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('Data structure: ${data.keys}');

        // Based on the CustomerAccountController response structure
        if (data['status'] == 'success' && data['token'] != null) {
          _authToken = data['token'];
          _currentUser = data['data'];
          _isAuthenticated = true;

          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _authToken!);
          await prefs.setString('current_user', json.encode(_currentUser));
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Register function
  Future<bool> register(String fullName, String email, String password) async {
    try {
      // Extract first and last name from full name
      List<String> nameParts = fullName.trim().split(' ');
      String firstName = nameParts.first;
      // If no last name provided, use the first name as last name to pass validation
      String lastName =
          nameParts.length > 1 ? nameParts.skip(1).join(' ') : firstName;

      // According to the API routes, use customer/register endpoint
      final registerUrl = '${AppConfig.apiBaseUrl}/customer/register';

      // Use the fields expected by CustomerAccountController
      final registerData = {
        'username': email, // Using email as username
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': '', // Optional field
        'address': '', // Optional field
      };

      print('====== REGISTER REQUEST ======');
      print('URL: $registerUrl');
      print('Headers: ${apiKeyHeaders}');
      print('Body: ${json.encode(registerData)}');

      // Make sure to use apiKeyHeaders with X-API-Key
      var response = await http.post(
        Uri.parse(registerUrl),
        headers: apiKeyHeaders,
        body: json.encode(registerData),
      );

      // If first attempt fails, try with form-encoded data
      if (response.statusCode >= 400) {
        print('Trying form-encoded approach...');

        // Create headers with API key for form submission
        final formHeaders = {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-API-Key': AppConfig.apiKey,
        };

        // Build form-encoded body with all required fields
        String formBody = 'username=${Uri.encodeComponent(email)}';
        formBody += '&email=${Uri.encodeComponent(email)}';
        formBody += '&password=${Uri.encodeComponent(password)}';
        formBody += '&firstName=${Uri.encodeComponent(firstName)}';
        formBody += '&lastName=${Uri.encodeComponent(lastName)}';
        formBody += '&phone=&address=';

        response = await http.post(
          Uri.parse(registerUrl),
          headers: formHeaders,
          body: formBody,
        );
      }

      print('====== REGISTER RESPONSE ======');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle response based on CustomerAccountController
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('Data structure: ${data.keys}');

        if (data['status'] == 'success') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // Logout function
  Future<bool> logout() async {
    try {
      if (_authToken != null) {
        // Ensure we have CSRF token
        await _fetchCsrfToken();

        // Call logout API
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/logout'),
          headers: authHeaders,
        );
      }

      // Clear local data regardless of API response
      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;
      _csrfToken = null;

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');

      return true;
    } catch (e) {
      // Even if API call fails, clear local data
      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;
      _csrfToken = null;

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');

      print('Logout error: $e');
      return false;
    }
  }

  // Get current user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!_isAuthenticated || _authToken == null) {
      return null;
    }

    try {
      // Try both possible endpoints for getting user info
      final endpoints = [
        '${AppConfig.apiBaseUrl}/customer/profile', // Try this first as it's known to work
        '${AppConfig.apiBaseUrl}/me',
        '${AppConfig.apiBaseUrl}/user',
      ];

      for (final endpoint in endpoints) {
        print('Trying to get user info from: $endpoint');

        final response = await http.get(
          Uri.parse(endpoint),
          headers: authHeaders,
        );

        print('User info response from $endpoint: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('User data structure: ${data.keys}');
          print('Full response: $data');

          Map<String, dynamic>? userData;

          // Check different response formats
          if (data['success'] == true && data['data'] != null) {
            userData = data['data'];
          } else if (data['status'] == 'success' && data['data'] != null) {
            userData = data['data'];
          } else if (data['user'] != null) {
            userData = data['user'];
          } else if (data is Map<String, dynamic>) {
            // The response might be the user object directly
            userData = data;
          }

          if (userData != null) {
            _currentUser = userData;

            // Update stored user data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('current_user', json.encode(_currentUser));

            return data; // Return the full response including any nested data
          }
        }
      }

      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    if (!_isAuthenticated || _authToken == null) {
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/customer/profile'),
        headers: authHeaders,
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _currentUser = data['data'];

          // Update stored user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', json.encode(_currentUser));

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!_isAuthenticated || _authToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/customer/change-password'),
        headers: authHeaders,
        body: json.encode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }
}
