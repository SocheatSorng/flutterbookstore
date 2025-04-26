import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/category.dart';
import 'package:flutterbookstore/config/app_config.dart';

class ApiService {
  // Use the centralized AppConfig for API URL
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Default HTTP headers with API key authentication
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': AppConfig.apiKey,
  };

  // Check if the device is connected to the network
  Future<bool> isConnectedToNetwork() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        'google.com',
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }

  // Create an HTTP client with a longer timeout
  http.Client createClient() {
    return http.Client();
  }

  // Helper method to implement retry logic with exponential backoff
  Future<http.Response> _getWithRetry(String url) async {
    final client = createClient();
    int attempts = 0;
    int backoffDelay = AppConfig.retryDelaySeconds;
    late http.Response response;

    while (attempts < AppConfig.maxRetryAttempts) {
      try {
        response = await client
            .get(Uri.parse(url), headers: defaultHeaders)
            .timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));

        client.close();
        if (response.statusCode == 200) {
          return response;
        }

        // If response code is not 200, try again with exponential backoff
        attempts++;
        if (attempts < AppConfig.maxRetryAttempts) {
          // Exponential backoff: increase delay each time
          await Future.delayed(Duration(seconds: backoffDelay));
          backoffDelay *= 2; // Double the delay for next retry
        }
      } catch (e) {
        attempts++;
        if (attempts >= AppConfig.maxRetryAttempts) {
          client.close();
          rethrow; // Rethrow the last exception if all attempts failed
        }
        // Exponential backoff
        await Future.delayed(Duration(seconds: backoffDelay));
        backoffDelay *= 2; // Double the delay for next retry
      }
    }

    client.close();
    return response;
  }

  // POST request with API key
  Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    final client = createClient();
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: defaultHeaders,
            body: json.encode(body),
          )
          .timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));
      return response;
    } finally {
      client.close();
    }
  }

  // PUT request with API key
  Future<http.Response> _put(String url, Map<String, dynamic> body) async {
    final client = createClient();
    try {
      final response = await client
          .put(Uri.parse(url), headers: defaultHeaders, body: json.encode(body))
          .timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));
      return response;
    } finally {
      client.close();
    }
  }

  // DELETE request with API key
  Future<http.Response> _delete(String url) async {
    final client = createClient();
    try {
      final response = await client
          .delete(Uri.parse(url), headers: defaultHeaders)
          .timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));
      return response;
    } finally {
      client.close();
    }
  }

  // Diagnostic function to check server connection
  Future<Map<String, dynamic>> checkServerConnection() async {
    final result = {
      'isConnected': false,
      'statusCode': null,
      'responseTime': 0,
      'error': null,
    };

    // First check if we're connected to a network
    bool networkConnected = await isConnectedToNetwork();
    if (!networkConnected) {
      result['error'] = 'Device not connected to any network';
      return result;
    }

    final stopwatch = Stopwatch()..start();
    final client = createClient();

    try {
      final response = await client
          .get(Uri.parse(baseUrl), headers: defaultHeaders)
          .timeout(Duration(seconds: 5)); // Short timeout for quick check

      result['isConnected'] = response.statusCode == 200;
      result['statusCode'] = response.statusCode;
      result['responseTime'] = stopwatch.elapsedMilliseconds;
    } catch (e) {
      result['error'] = e.toString();
    } finally {
      stopwatch.stop();
      client.close();
    }

    return result;
  }

  // Fetch all books
  Future<List<Book>> getBooks() async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      final response = await _getWithRetry('$baseUrl/books');

      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> booksJson = data['data'];
        return booksJson.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load books: ${data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load books: $e');
    }
  }

  // Fetch categories
  Future<List<BookCategory>> getCategories() async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      final response = await _getWithRetry('$baseUrl/categories');

      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> categoriesJson = data['data'];
        return categoriesJson
            .map((json) => BookCategory.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load categories: ${data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // Fetch book by ID
  Future<Book> getBookById(int id) async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      final response = await _getWithRetry('$baseUrl/books/$id');

      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return Book.fromJson(data['data']);
      } else {
        throw Exception(
          'Failed to load book: ${data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load book: $e');
    }
  }
}
