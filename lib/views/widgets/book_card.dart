import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/services/auth_service.dart';
import 'package:flutterbookstore/services/cart_service.dart';
import 'package:flutterbookstore/views/screens/book_detail_page.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String coverImage;
  final double price;
  final double rating;
  final Book? bookData;

  const BookCard({
    Key? key,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.price,
    required this.rating,
    this.bookData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (bookData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailPage(book: bookData!),
            ),
          );
        } else {
          // Show a snackbar indicating the book details aren't available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Book details not available'),
              backgroundColor: AppColor.primary,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        coverImage.startsWith('http') ||
                                coverImage.startsWith('https')
                            ? Image.network(
                              coverImage,
                              width: 150,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 150,
                                  height: 200,
                                  color: AppColor.primary.withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.book,
                                        size: 40,
                                        color: AppColor.primary,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.dark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                            : Image.asset(
                              coverImage,
                              width: 150,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 150,
                                  height: 200,
                                  color: AppColor.primary.withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.book,
                                        size: 40,
                                        color: AppColor.primary,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.dark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  // Add to cart button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child:
                        bookData != null
                            ? AddToCartButton(book: bookData!)
                            : SizedBox(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.dark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            // Author
            Text(
              'by $author',
              style: TextStyle(fontSize: 12, color: AppColor.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            // Price and Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
                // Rating
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.dark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddToCartButton extends StatefulWidget {
  final Book book;

  const AddToCartButton({Key? key, required this.book}) : super(key: key);

  @override
  _AddToCartButtonState createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _addToCart() async {
    // Check if user is logged in
    if (!_authService.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await CartService.addToCart(widget.book, quantity: 1);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.book.title} added to your cart!'),
            backgroundColor: AppColor.primary,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text('You need to login to add items to your cart.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isLoading ? null : _addToCart,
          child: SizedBox(
            width: 36,
            height: 36,
            child:
                _isLoading
                    ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 20,
                    ),
          ),
        ),
      ),
    );
  }
}
