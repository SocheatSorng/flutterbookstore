import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/views/screens/cart_page.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
import 'package:flutterbookstore/services/cart_service.dart';
import 'package:flutterbookstore/services/auth_service.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  _BookDetailPageState createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  int quantity = 1;
  bool isFavorite = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'Added to your wishlist!'
              : 'Removed from your wishlist!',
        ),
        backgroundColor: AppColor.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

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
      final success = await CartService.addToCart(
        widget.book,
        quantity: quantity,
      );

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

  String generateDescription(String title) {
    // Generate a fake description based on the book title
    return "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ${title} is a captivating book that takes readers on a journey through imagination and knowledge. "
        "The author has masterfully crafted a narrative that is both engaging and thought-provoking. "
        "This book explores themes of adventure, discovery, and personal growth, making it a must-read for all book lovers. "
        "With its rich character development and intricate plot, ${title} stands as a testament to the power of storytelling in modern literature.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Book Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: AppColor.dark),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
            icon: Icon(Icons.shopping_cart_outlined, color: AppColor.dark),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: AppColor.primarySoft,
          ),
        ),
      ),
      // Buy Now Button
      bottomNavigationBar: Container(
        height: 80,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColor.border, width: 1)),
        ),
        child: Row(
          children: [
            // Add to cart button
            Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addToCart,
                child:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
              ),
            ),
            // Buy now button
            Expanded(
              flex: 5,
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          // Check if user is logged in before proceeding
                          if (!_authService.isAuthenticated) {
                            _showLoginRequiredDialog();
                            return;
                          }

                          await _addToCart();

                          if (!mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CartPage()),
                          );
                        },
                child:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'Buy Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColor.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          // Book Cover and Basic Info Section
          Container(
            color: AppColor.lightGrey.withOpacity(0.3),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover Image with Favorite Button
                Stack(
                  children: [
                    // Book Image
                    Center(
                      child: Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              widget.book.image != null &&
                                      widget.book.image!.isNotEmpty
                                  ? Image.network(
                                    widget.book.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 280,
                                        width: 200,
                                        color: AppColor.primary.withOpacity(
                                          0.1,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.book,
                                              size: 80,
                                              color: AppColor.primary,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              widget.book.title,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColor.dark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                  : Container(
                                    height: 280,
                                    width: 200,
                                    color: AppColor.primary.withOpacity(0.1),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.book,
                                          size: 80,
                                          color: AppColor.primary,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          widget.book.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.dark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    // Favorite Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColor.dark,
                            size: 18,
                          ),
                          onPressed: _toggleFavorite,
                          constraints: BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Title
                Text(
                  widget.book.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.dark,
                  ),
                ),
                SizedBox(height: 8),
                // Author
                Text(
                  'by ${widget.book.author}',
                  style: TextStyle(fontSize: 14, color: AppColor.grey),
                ),
                SizedBox(height: 12),
                // Price and Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      '\$${widget.book.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColor.dark,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(120 reviews)',
                          style: TextStyle(fontSize: 12, color: AppColor.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quantity Section
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Quantity:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.dark,
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColor.lightGrey,
                  ),
                  child: Row(
                    children: [
                      // Decrease Button
                      IconButton(
                        icon: Icon(
                          Icons.remove,
                          color: quantity > 1 ? AppColor.dark : AppColor.grey,
                          size: 16,
                        ),
                        onPressed: _decreaseQuantity,
                      ),
                      // Quantity Display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColor.dark,
                          ),
                        ),
                      ),
                      // Increase Button
                      IconButton(
                        icon: Icon(Icons.add, color: AppColor.dark, size: 16),
                        onPressed: _increaseQuantity,
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // Stock Information
                Text(
                  'In Stock: ${widget.book.stockQuantity}',
                  style: TextStyle(fontSize: 12, color: AppColor.grey),
                ),
              ],
            ),
          ),

          // Book Description Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.dark,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  // Create a description based on the book title if not available
                  generateDescription(widget.book.title),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColor.grey,
                  ),
                ),
              ],
            ),
          ),

          // Book Details Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.dark,
                  ),
                ),
                SizedBox(height: 12),
                _buildDetailRow(
                  'Category',
                  'Category ${widget.book.categoryID}',
                ),
                _buildDetailRow('Published', widget.book.createdAt),
                _buildDetailRow('Language', 'English'),
                _buildDetailRow('Pages', '${100 + (widget.book.bookID * 15)}'),
                _buildDetailRow('ISBN', '978-${1000000 + widget.book.bookID}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColor.grey),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
