import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../models/book.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class CartService {
  static final List<Cart> _cartData = [];
  static final AuthService _authService = AuthService();

  // Sample data for testing UI
  static List<Cart> get dummyCartData {
    if (_cartData.isEmpty) {
      _cartData.addAll([
        Cart(
          id: '1',
          bookId: 'book1',
          title: 'Harry Potter and the Philosopher\'s Stone',
          image: 'assets/images/book1.jpg',
          price: 150000,
        ),
        Cart(
          id: '2',
          bookId: 'book2',
          title: 'To Kill a Mockingbird',
          image: 'assets/images/book2.jpg',
          price: 120000,
          quantity: 2,
        ),
        Cart(
          id: '3',
          bookId: 'book3',
          title: 'The Great Gatsby',
          image: 'assets/images/book3.jpg',
          price: 135000,
        ),
      ]);
    }
    return _cartData;
  }

  // Get all cart items
  static List<Cart> get cartData => _cartData;

  // Add item to cart with API integration
  static Future<bool> addToCart(Book book, {int quantity = 1}) async {
    // Check if user is authenticated
    if (!_authService.isAuthenticated) {
      return false;
    }

    try {
      // Get the user ID from the current user data
      final userId = _authService.currentUser?['AccountID'];
      if (userId == null) {
        print('User ID is null');
        return false;
      }

      // Ensure we're sending user ID as integer if it's expected as int by the API
      final userIdValue = userId is String ? int.tryParse(userId) ?? userId : userId;
      
      // Create a properly formatted request body with AccountID instead of UserID
      final requestBody = {
        'AccountID': userIdValue,  // Changed from UserID to AccountID
        'BookID': book.bookID,
        'Quantity': quantity,
      };

      print('Adding to cart: ${json.encode(requestBody)}');

      // Prepare API request
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/carts'),
        headers: _authService.authHeaders,
        body: json.encode(requestBody),
      );

      // Handle API response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await fetchCartItems(); // Refresh cart items from API
          return true;
        }
      }

      print('Add to cart error: ${response.body}');
      return false;
    } catch (e) {
      print('Add to cart exception: $e');
      return false;
    }
  }

  // Fetch cart items from API
  static Future<List<Cart>> fetchCartItems() async {
    if (!_authService.isAuthenticated) {
      return [];
    }

    try {
      final userId = _authService.currentUser?['AccountID'];
      if (userId == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/carts/user/$userId'),
        headers: _authService.authHeaders,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> cartItems = data['data'];

          _cartData.clear(); // Clear existing cart

          // Convert API response to Cart objects
          for (var item in cartItems) {
            final book = item['book'];
            if (book != null) {
              _cartData.add(
                Cart(
                  id: item['CartID'].toString(),
                  bookId: book['BookID'].toString(),
                  title: book['Title'],
                  image: book['Image'] ?? '',
                  price: double.parse(book['Price'].toString()),
                  quantity: item['Quantity'],
                ),
              );
            }
          }

          return _cartData;
        }
      }

      return [];
    } catch (e) {
      print('Fetch cart error: $e');
      return [];
    }
  }

  // Remove item from cart via API
  static Future<bool> removeFromCart(String id) async {
    if (!_authService.isAuthenticated) {
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/carts/$id'),
        headers: _authService.authHeaders,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchCartItems(); // Refresh cart items
        return true;
      }

      return false;
    } catch (e) {
      print('Remove from cart error: $e');
      return false;
    }
  }

  // Update quantity via API
  static Future<bool> updateQuantity(String id, int quantity) async {
    if (!_authService.isAuthenticated) {
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/carts/$id'),
        headers: _authService.authHeaders,
        body: json.encode({
          'Quantity': max(1, quantity), // Ensure quantity is at least 1
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchCartItems(); // Refresh cart items
        return true;
      }

      return false;
    } catch (e) {
      print('Update quantity error: $e');
      return false;
    }
  }

  // Clear cart via API
  static Future<bool> clearCart() async {
    if (!_authService.isAuthenticated) {
      return false;
    }

    try {
      final userId = _authService.currentUser?['AccountID'];
      if (userId == null) {
        return false;
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/carts/user/$userId/clear'),
        headers: _authService.authHeaders,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _cartData.clear();
        return true;
      }

      return false;
    } catch (e) {
      print('Clear cart error: $e');
      return false;
    }
  }

  // Calculate total price
  static double get totalPrice {
    return _cartData.fold(0, (total, item) => total + item.total);
  }

  // Get number of items in cart
  static int get itemCount {
    return _cartData.fold(0, (total, item) => total + item.quantity);
  }

  // Check if a book is already in the cart
  static bool isInCart(int bookId) {
    return _cartData.any((item) => int.parse(item.bookId) == bookId);
  }
}
