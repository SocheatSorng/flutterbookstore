import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constant/app_color.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import 'checkout_page.dart';
import '../widgets/cart_tile.dart';
import 'login_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Cart> cartData = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    if (!_authService.isAuthenticated) {
      _redirectToLogin();
      return;
    }

    try {
      await CartService.fetchCartItems();
      setState(() {
        cartData = CartService.cartData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        _isLoading = false;
      });
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
            title: Text('Login Required'),
            content: Text('You need to be logged in to view your cart.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
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
    });
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_authService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cart'),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: AppColor.dark),
          ),
        ),
        body: Center(child: Text('Please login to view your cart')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Your Cart',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${CartService.itemCount} items',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: AppColor.dark),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: AppColor.primarySoft,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      // Checkout Button
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColor.border, width: 1)),
        ),
        child: ElevatedButton(
          onPressed:
              cartData.isEmpty
                  ? null
                  : () {
                    // Navigate to checkout page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(),
                      ),
                    );
                  },
          child: Text(
            'Checkout (${CartService.itemCount} items)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColor.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            disabledBackgroundColor: AppColor.primary.withOpacity(0.4),
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : cartData.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: AppColor.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.dark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Browse books and add them to your cart',
                      style: TextStyle(fontSize: 14, color: AppColor.grey),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Browse Books'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : ListView(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                children: [
                  // Cart List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: cartData.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return CartTile(
                        cart: cartData[index],
                        onQuantityChanged: _updateState,
                      );
                    },
                  ),
                  // Order Summary
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.dark,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.grey,
                              ),
                            ),
                            Text(
                              '\$${CartService.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColor.dark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Shipping',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.grey,
                              ),
                            ),
                            Text(
                              'Free',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColor.dark,
                              ),
                            ),
                            Text(
                              '\$${CartService.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColor.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
