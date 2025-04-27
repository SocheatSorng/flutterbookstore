import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/book_detail.dart';
import 'package:flutterbookstore/models/book_review.dart';
import 'package:flutterbookstore/views/screens/cart_page.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
import 'package:flutterbookstore/services/cart_service.dart';
import 'package:flutterbookstore/services/auth_service.dart';
import 'package:flutterbookstore/services/api_service.dart';

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
  bool _isLoadingDetails = true;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  BookDetail? _bookDetail;
  String _errorLoadingDetails = '';
  List<BookReview>? _bookReviews;
  bool _isLoadingReviews = true;
  bool _hasReviewError = false;

  @override
  void initState() {
    super.initState();
    _fetchBookDetails();
    _loadBookReviews();
  }

  Future<void> _fetchBookDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _errorLoadingDetails = '';
    });

    try {
      final details = await _apiService.getBookDetails(widget.book.bookID);
      setState(() {
        _bookDetail = details;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _errorLoadingDetails = e.toString();
        _isLoadingDetails = false;
      });
      print("Error fetching book details: $e");
    }
  }

  Future<void> _loadBookReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _hasReviewError = false;
    });

    try {
      // This would normally be an API call to get reviews
      // For demonstration, we'll create mock reviews after a short delay
      await Future.delayed(Duration(seconds: 1));
      
      if (!mounted) return;

      // Mock reviews data
      final List<BookReview> mockReviews = [
        BookReview(
          id: 1,
          bookId: widget.book.bookID,
          customerName: "John Doe",
          rating: 5,
          content: "This book exceeded my expectations! The storytelling is captivating and the characters are well-developed.",
          createdAt: "2023-09-15",
        ),
        BookReview(
          id: 2,
          bookId: widget.book.bookID,
          customerName: "Jane Smith",
          rating: 4,
          content: "A great read overall, though I found some parts to be a bit slow. Still would recommend it!",
          createdAt: "2023-08-28",
        ),
        BookReview(
          id: 3,
          bookId: widget.book.bookID,
          customerName: "David Wilson",
          rating: 5,
          content: "Absolutely loved this book. Couldn't put it down once I started reading!",
          createdAt: "2023-07-10",
        ),
      ];

      setState(() {
        _bookReviews = mockReviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasReviewError = true;
        _isLoadingReviews = false;
      });
      print("Error loading reviews: $e");
    }
  }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: AppColor.dark, size: 20),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartPage()),
                    );
                  },
                  icon: Icon(Icons.shopping_cart_outlined, color: AppColor.dark, size: 20),
                ),
                if (CartService.itemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${CartService.itemCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Buy Now Button
      bottomNavigationBar: Container(
        height: 90,
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -1),
            ),
          ],
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
                  elevation: 2,
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
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        physics: BouncingScrollPhysics(),
        children: [
          // Book Cover and Basic Info Section
          Container(
            decoration: BoxDecoration(
              color: AppColor.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Image
                Stack(
                  children: [
                    // Book Image
                    Container(
                      height: 380,
                      width: double.infinity,
                      child: widget.book.image != null && widget.book.image!.isNotEmpty
                        ? Image.network(
                            widget.book.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColor.primary.withOpacity(0.1),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.book, size: 80, color: AppColor.primary),
                                    SizedBox(height: 16),
                                    Text(
                                      widget.book.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.dark,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColor.primary.withOpacity(0.1),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book, size: 80, color: AppColor.primary),
                                SizedBox(height: 16),
                                Text(
                                  widget.book.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.dark,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColor.lightGrey.withOpacity(0.3),
                              AppColor.lightGrey.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Favorite Button
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColor.dark,
                            size: 20,
                          ),
                          onPressed: _toggleFavorite,
                          constraints: BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Book Info
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with animation
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          widget.book.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColor.dark,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Author with animation
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 700),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'by ${widget.book.author}',
                          style: TextStyle(
                            fontSize: 16, 
                            color: AppColor.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Price and Rating Row with animation
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Text(
                              '\$${widget.book.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColor.primary,
                              ),
                            ),
                            // Rating
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.5',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '(120)',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: AppColor.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quantity Section
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Quantity:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.dark,
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColor.lightGrey,
                  ),
                  child: Row(
                    children: [
                      // Decrease Button
                      IconButton(
                        icon: Icon(
                          Icons.remove,
                          color: quantity > 1 ? AppColor.dark : AppColor.grey,
                          size: 18,
                        ),
                        onPressed: _decreaseQuantity,
                      ),
                      // Quantity Display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
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
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Increase Button
                      IconButton(
                        icon: Icon(Icons.add, color: AppColor.dark, size: 18),
                        onPressed: _increaseQuantity,
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // Stock Information
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'In Stock: ${widget.book.stockQuantity}',
                    style: TextStyle(
                      fontSize: 12, 
                      color: AppColor.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Book Description Section
          _buildDescriptionSection(),

          // Book Details Section
          _buildDetailsSection(),
          
          // Reviews Section
          _buildReviewsSection(),
          
          SizedBox(height: 30),
        ],
      ),
    );
  }

  // Book Description Section
  Widget _buildDescriptionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColor.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'Book Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.dark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_isLoadingDetails)
            Center(
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Loading book description...',
                    style: TextStyle(color: AppColor.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (_errorLoadingDetails.isNotEmpty)
            Text(
              // Fallback to generated description if there's an error
              generateDescription(widget.book.title),
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColor.grey.withOpacity(0.9),
              ),
            )
          else
            Text(
              // Use the actual description from API if available
              _bookDetail?.description != null && _bookDetail!.description.isNotEmpty
                  ? _bookDetail!.description
                  : generateDescription(widget.book.title),
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColor.grey.withOpacity(0.9),
              ),
            ),
        ],
      ),
    );
  }

  // Book Details Section
  Widget _buildDetailsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColor.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'Book Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.dark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            'Category',
            'Category ${widget.book.categoryID}',
          ),
          if (_bookDetail != null) ...[
            _buildDetailRow('Publisher', _bookDetail!.publisher.isNotEmpty ? _bookDetail!.publisher : 'Unknown'),
            _buildDetailRow('Language', _bookDetail!.language.isNotEmpty ? _bookDetail!.language : 'English'),
            _buildDetailRow('Pages', _bookDetail!.pageCount > 0 ? _bookDetail!.pageCount.toString() : '${100 + (widget.book.bookID * 15)}'),
            _buildDetailRow('ISBN', _bookDetail!.isbn.isNotEmpty ? _bookDetail!.isbn : '978-${1000000 + widget.book.bookID}'),
            _buildDetailRow('Format', _bookDetail!.format.isNotEmpty ? _bookDetail!.format : 'Paperback'),
            _buildDetailRow('Dimensions', _bookDetail!.dimensions.isNotEmpty ? _bookDetail!.dimensions : 'Standard'),
            _buildDetailRow('Publication Date', _bookDetail!.publicationDate.isNotEmpty ? _bookDetail!.publicationDate : widget.book.createdAt),
          ] else ...[
            _buildDetailRow('Published', widget.book.createdAt),
            _buildDetailRow('Language', 'English'),
            _buildDetailRow('Pages', '${100 + (widget.book.bookID * 15)}'),
            _buildDetailRow('ISBN', '978-${1000000 + widget.book.bookID}'),
          ],
        ],
      ),
    );
  }

  // Helper function to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.dark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reviews Section
  Widget _buildReviewsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.dark,
                    ),
                  ),
                ],
              ),
              if (_bookReviews != null && _bookReviews!.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    // Navigate to all reviews
                  },
                  icon: Icon(Icons.arrow_forward, size: 16, color: AppColor.primary),
                  label: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (_isLoadingReviews)
            Center(
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading reviews...',
                    style: TextStyle(
                      color: AppColor.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else if (_hasReviewError)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Failed to load reviews',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please check your connection and try again',
                          style: TextStyle(color: Colors.red[400]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadBookReviews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else if (_bookReviews == null || _bookReviews!.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      color: Colors.grey[400],
                      size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to review this book!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add review functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.edit, color: Colors.white, size: 16),
                      label: Text(
                        'Write a Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _bookReviews!.take(3).map((review) => _buildReviewItem(review)).toList(),
            ),
          
          if (_bookReviews != null && _bookReviews!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Add review functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColor.primary,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                    side: BorderSide(color: AppColor.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text(
                    'Add Your Review',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Single Review Item
  Widget _buildReviewItem(BookReview review) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primary.withOpacity(0.7),
                      AppColor.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName.isNotEmpty ? review.customerName : 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColor.dark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      review.createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: review.rating >= 4
                      ? Colors.green[50]
                      : review.rating >= 3
                          ? Colors.amber[50]
                          : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: review.rating >= 4
                        ? Colors.green[200]!
                        : review.rating >= 3
                            ? Colors.amber[200]!
                            : Colors.red[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${review.rating}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: review.rating >= 4
                            ? Colors.green[700]
                            : review.rating >= 3
                                ? Colors.amber[700]
                                : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.content.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Text(
                review.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.dark.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
