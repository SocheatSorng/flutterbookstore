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

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Headers with API key for unauthenticated requests
  Map<String, String> get apiKeyHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': AppConfig.apiKey,
  };

  // Headers with both API key and authentication token for authenticated requests
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': AppConfig.apiKey,
    'Authorization': 'Bearer $_authToken',
  };

  // Initialize authentication state from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    final userJson = prefs.getString('current_user');

    if (_authToken != null && userJson != null) {
      _isAuthenticated = true;
      _currentUser = json.decode(userJson);
    }
  }

  // Login function
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/login'),
        headers: apiKeyHeaders,
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _authToken = data['data']['token'];
          _currentUser = data['data']['user'];
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
      return false;
    }
  }

  // Logout function
  Future<bool> logout() async {
    try {
      if (_authToken != null) {
        // Call logout API if needed
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/logout'),
          headers: authHeaders,
        );
      }

      // Clear local data regardless of API response
      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;

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

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');

      return false;
    }
  }

  // Get current user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!_isAuthenticated || _authToken == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/me'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _currentUser = data['data'];

          // Update stored user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', json.encode(_currentUser));

          return _currentUser;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
