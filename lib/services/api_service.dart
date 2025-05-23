import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/category.dart';
import 'package:flutterbookstore/models/book_detail.dart';
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
      // Skip network check in web platform
      if (kIsWeb) {
        return true; // Assume connected when running in a browser
      }

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

  // Fetch all books
  Future<List<Book>> getBooks() async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      final response = await _getWithRetry('$baseUrl/books');

      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> booksJson = data['data'];
          return booksJson.map((json) => Book.fromJson(json)).toList();
        } else {
          // Fallback: Try to parse as direct array
          final List<dynamic> directData = json.decode(response.body);
          return directData.map((json) => Book.fromJson(json)).toList();
          throw Exception(
            'Failed to load books: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } catch (parseError) {
        // If parsing fails, create mock data for testing
        return List.generate(
          10,
          (index) => Book(
            bookID: index + 1,
            categoryID: (index % 5) + 1,
            title: 'Book ${index + 1}',
            author: 'Author ${index % 4 + 1}',
            price: ((index + 1) * 9.99),
            stockQuantity: 100,
            image: 'https://via.placeholder.com/150?text=Book${index + 1}',
            createdAt: DateTime.now().toString(),
            category: {
              'CategoryID': (index % 5) + 1,
              'Name': 'Category ${(index % 5) + 1}',
            },
          ),
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

      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> categoriesJson = data['data'];
          return categoriesJson
              .map((json) => BookCategory.fromJson(json))
              .toList();
        } else {
          // Fallback: Try to parse as direct array
          final List<dynamic> directData = json.decode(response.body);
          return directData.map((json) => BookCategory.fromJson(json)).toList();
          throw Exception(
            'Failed to load categories: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } catch (parseError) {
        // If parsing fails, create mock data for testing
        return [
          BookCategory(
            categoryID: 1,
            name: 'Fiction',
            description: 'Fiction books',
            image: null,
            createdAt: DateTime.now().toString(),
            booksCount: 10,
          ),
          BookCategory(
            categoryID: 2,
            name: 'Non-Fiction',
            description: 'Non-Fiction books',
            image: null,
            createdAt: DateTime.now().toString(),
            booksCount: 8,
          ),
          BookCategory(
            categoryID: 3,
            name: 'Science',
            description: 'Science books',
            image: null,
            createdAt: DateTime.now().toString(),
            booksCount: 5,
          ),
          BookCategory(
            categoryID: 4,
            name: 'Technology',
            description: 'Technology books',
            image: null,
            createdAt: DateTime.now().toString(),
            booksCount: 7,
          ),
          BookCategory(
            categoryID: 5,
            name: 'History',
            description: 'History books',
            image: null,
            createdAt: DateTime.now().toString(),
            booksCount: 6,
          ),
        ];
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

  // Search books by query
  Future<List<Book>> searchBooks(String query) async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      // Check if query is empty
      if (query.trim().isEmpty) {
        return getBooks(); // Return all books if query is empty
      }

      // Create a new http client for this request
      final client = http.Client();
      try {
        // Encode the query for URL
        final encodedQuery = Uri.encodeComponent(query);
        final uri = Uri.parse('$baseUrl/books/search?q=$encodedQuery');

        // Use the new client directly instead of _getWithRetry
        final response = await client
            .get(uri, headers: ApiService.defaultHeaders)
            .timeout(const Duration(seconds: 10));

        client.close(); // Close the client after use

        if (response.statusCode == 200) {
          try {
            final Map<String, dynamic> data = json.decode(response.body);

            if (data['success'] == true && data['data'] != null) {
              final List<dynamic> booksJson = data['data'];
              return booksJson.map((json) => Book.fromJson(json)).toList();
            }
          } catch (parseError) {
            // Continue to fallback if parsing fails
          }
        }

        // If we reached here, either the API doesn't support search or returned an error
        // Do client-side filtering instead
        final booksList = await getBooks();

        // Filter the books that match the query
        return booksList.where((book) {
          final titleMatch = book.title.toLowerCase().contains(
            query.toLowerCase(),
          );
          final authorMatch = book.author.toLowerCase().contains(
            query.toLowerCase(),
          );
          return titleMatch || authorMatch;
        }).toList();
      } finally {
        // Ensure client is closed even if an exception occurs
        client.close();
      }
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  // Fetch books by category
  Future<List<Book>> getBooksByCategory(int categoryId) async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      final response = await _getWithRetry(
        '$baseUrl/categories/$categoryId/books',
      );

      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> booksJson = data['data'];
          return booksJson.map((json) => Book.fromJson(json)).toList();
        } else {
          // Fallback: Try to parse as direct array
          final List<dynamic> directData = json.decode(response.body);
          return directData.map((json) => Book.fromJson(json)).toList();
          throw Exception(
            'Failed to load books for category: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } catch (parseError) {
        // If parsing fails, get all books and filter by category
        final allBooks = await getBooks();
        return allBooks.where((book) => book.categoryID == categoryId).toList();
      }
    } catch (e) {
      throw Exception('Failed to load books for category: $e');
    }
  }

  // Fetch book details
  Future<BookDetail?> getBookDetails(int bookId) async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      final response = await _getWithRetry(
        'http://18.140.63.109/api/book-details/book/$bookId',
      );

      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['data'] != null) {
          final Map<String, dynamic> detailJson = data['data'];
          return BookDetail.fromJson(detailJson);
        } else {
          throw Exception(
            'Failed to load book details: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } catch (parseError) {
        // If parsing fails, return null
        print('Error parsing book details: $parseError');
        return null;
      }
    } catch (e) {
      print('Error fetching book details: $e');
      throw Exception('Failed to load book details: $e');
    }
  }

  // Add these methods to the ApiService class to implement sorting functionality

  Future<List<Book>> getSortedBooks({
    String sortBy = 'title',
    String sortDirection = 'asc',
    int? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      // Build URL with query parameters
      String url =
          '$baseUrl/books/sort?sort_by=$sortBy&sort_direction=$sortDirection';

      // Add optional parameters if provided
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }

      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }

      // Add price range filters if provided
      if (minPrice != null) {
        url += '&min_price=$minPrice';
      }

      if (maxPrice != null) {
        url += '&max_price=$maxPrice';
      }

      final response = await _getWithRetry(url);

      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> booksJson =
              data['data']['data']; // Access nested data
          return booksJson.map((json) => Book.fromJson(json)).toList();
        } else {
          // Fallback: Try to parse as direct array
          final List<dynamic> directData = json.decode(response.body);
          return directData.map((json) => Book.fromJson(json)).toList();
          throw Exception(
            'Failed to load sorted books: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } catch (parseError) {
        // If parsing fails, fall back to client-side sorting and filtering
        final allBooks = await getBooks();

        // Apply price filter
        var filteredBooks = allBooks;
        if (minPrice != null || maxPrice != null) {
          filteredBooks =
              allBooks.where((book) {
                bool matches = true;
                if (minPrice != null) {
                  matches = matches && book.price >= minPrice;
                }
                if (maxPrice != null) {
                  matches = matches && book.price <= maxPrice;
                }
                return matches;
              }).toList();
        }

        // Sort books based on specified field and direction
        return _sortBooksLocally(filteredBooks, sortBy, sortDirection);
      }
    } catch (e) {
      throw Exception('Failed to load sorted books: $e');
    }
  }

  // Method to get books by category with sorting
  Future<List<Book>> getSortedBooksByCategory(
    int categoryId, {
    String sortBy = 'title',
    String sortDirection = 'asc',
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      // Verify network connection first
      bool isConnected = await isConnectedToNetwork();
      if (!isConnected) {
        throw Exception('No network connection available');
      }

      // Try to get sorted books with category filter
      String url =
          '$baseUrl/books/sort?sort_by=$sortBy&sort_direction=$sortDirection&category_id=$categoryId';

      // Add price range filters if provided
      if (minPrice != null) {
        url += '&min_price=$minPrice';
      }

      if (maxPrice != null) {
        url += '&max_price=$maxPrice';
      }

      final response = await _getWithRetry(url);

      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> booksJson =
              data['data']['data']; // Access nested data
          return booksJson.map((json) => Book.fromJson(json)).toList();
        }
      } catch (e) {
        // Continue to fallback if parsing fails
      }

      // Fallback: Get books by category then sort and filter them locally
      final books = await getBooksByCategory(categoryId);

      // Apply price filter
      var filteredBooks = books;
      if (minPrice != null || maxPrice != null) {
        filteredBooks =
            books.where((book) {
              bool matches = true;
              if (minPrice != null) {
                matches = matches && book.price >= minPrice;
              }
              if (maxPrice != null) {
                matches = matches && book.price <= maxPrice;
              }
              return matches;
            }).toList();
      }

      return _sortBooksLocally(filteredBooks, sortBy, sortDirection);
    } catch (e) {
      throw Exception('Failed to load books for category: $e');
    }
  }

  // Helper method for client-side sorting
  List<Book> _sortBooksLocally(
    List<Book> books,
    String sortBy,
    String sortDirection,
  ) {
    switch (sortBy) {
      case 'title':
        books.sort(
          (a, b) =>
              sortDirection == 'asc'
                  ? a.title.compareTo(b.title)
                  : b.title.compareTo(a.title),
        );
        break;
      case 'author':
        books.sort(
          (a, b) =>
              sortDirection == 'asc'
                  ? a.author.compareTo(b.author)
                  : b.author.compareTo(a.author),
        );
        break;
      case 'price':
        books.sort(
          (a, b) =>
              sortDirection == 'asc'
                  ? a.price.compareTo(b.price)
                  : b.price.compareTo(a.price),
        );
        break;
      case 'date':
        books.sort(
          (a, b) =>
              sortDirection == 'asc'
                  ? a.createdAt.compareTo(b.createdAt)
                  : b.createdAt.compareTo(a.createdAt),
        );
        break;
      default:
        // Default sort by title
        books.sort((a, b) => a.title.compareTo(b.title));
    }
    return books;
  }

  // Get all available price ranges from the books
  Future<Map<String, double>> getBookPriceRange() async {
    try {
      final books = await getBooks();

      if (books.isEmpty) {
        return {'min': 0, 'max': 100}; // Default range if no books
      }

      double minPrice = books
          .map((book) => book.price)
          .reduce((a, b) => a < b ? a : b);
      double maxPrice = books
          .map((book) => book.price)
          .reduce((a, b) => a > b ? a : b);

      // Round min down and max up to nearest whole numbers
      minPrice = (minPrice.floor()).toDouble();
      maxPrice = (maxPrice.ceil()).toDouble();

      // Add small buffer to max
      maxPrice = maxPrice + 10;

      return {'min': minPrice, 'max': maxPrice};
    } catch (e) {
      return {'min': 0, 'max': 100}; // Fallback range
    }
  }
}
