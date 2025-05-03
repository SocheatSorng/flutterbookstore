import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import 'checkout_page.dart';
import '../widgets/enhanced_cart_tile.dart';
import '../widgets/cart_skeleton_loader.dart';
import '../widgets/empty_cart_view.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/cart_app_bar.dart';
import 'login_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  CartPageState createState() => CartPageState();
}

class CartPageState extends State<CartPage> with TickerProviderStateMixin {
  List<Cart> cartData = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  final AuthService _authService = AuthService();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _loadCartItems();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    if (!_authService.isAuthenticated) {
      _redirectToLogin();
      return;
    }

    try {
      await CartService.fetchCartItems();

      if (mounted) {
        setState(() {
          cartData = CartService.cartData;
          _isLoading = false;
        });

        // Start fade-in animation
        _fadeController.reset();
        _fadeController.forward();
      }
    } catch (e) {
      // Log error (in a production app, use a proper logging framework)
      debugPrint('Error loading cart items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load cart items. Please try again.';
        });
      }
    }
  }

  void _redirectToLogin() {
    // Delay to prevent building during build
    Future.delayed(Duration.zero, () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Login Required'),
            content: Text('You need to be logged in to view your cart.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: Text('Cancel', style: TextStyle(color: AppColor.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    });
  }

  void _updateState() {
    setState(() {
      cartData = CartService.cartData;
    });
  }

  void _navigateToCheckout() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CheckoutPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cart'),
          backgroundColor: Colors.white,
          foregroundColor: AppColor.dark,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColor.dark,
              size: 20,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppColor.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Please login to view your cart',
                style: TextStyle(fontSize: 16, color: AppColor.dark),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CartAppBar(
        onBackPressed: () => Navigator.of(context).pop(),
        onClearCart: _loadCartItems,
        isEmpty: cartData.isEmpty,
      ),
      body:
          _isLoading
              ? CartSkeletonLoader()
              : _isError
              ? _buildErrorView()
              : cartData.isEmpty
              ? EmptyCartView(
                onStartShopping: () => Navigator.of(context).pop(),
                onRefresh: _loadCartItems,
              )
              : _buildCartContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.dark,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Failed to load your cart. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColor.grey),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCartItems,
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index < cartData.length) {
                      // Cart items
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: EnhancedCartTile(
                          cart: cartData[index],
                          onQuantityChanged: _updateState,
                          onRemove: () {
                            setState(() {
                              cartData = CartService.cartData;
                            });
                          },
                        ),
                      );
                    } else if (index == cartData.length) {
                      // Order summary card
                      return OrderSummaryCard(
                        onCheckout: _navigateToCheckout,
                        isEnabled: cartData.isNotEmpty,
                      );
                    }
                    return null;
                  }, childCount: cartData.length + 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
