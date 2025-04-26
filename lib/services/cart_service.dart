import 'dart:math';
import '../models/cart.dart';

class CartService {
  static final List<Cart> _cartData = [];

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

  // Add item to cart
  static void addToCart(Cart item) {
    final existingIndex = _cartData.indexWhere(
      (cart) => cart.bookId == item.bookId,
    );

    if (existingIndex >= 0) {
      // If item already exists, increment quantity
      _cartData[existingIndex].quantity += 1;
    } else {
      // Otherwise add new item
      _cartData.add(item);
    }
  }

  // Remove item from cart
  static void removeFromCart(String id) {
    _cartData.removeWhere((item) => item.id == id);
  }

  // Update quantity
  static void updateQuantity(String id, int quantity) {
    final index = _cartData.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartData[index].quantity = max(
        1,
        quantity,
      ); // Ensure quantity is at least 1
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

  // Clear cart
  static void clearCart() {
    _cartData.clear();
  }
}
