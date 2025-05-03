import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constant/app_color.dart';
import '../../config/app_config.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/paypal_service.dart';
import 'order_success_page.dart';
import 'paypal_checkout_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Form fields
  String _fullName = '';
  String _address = '';
  String _city = '';
  String _zipCode = '';
  String _phone = '';
  String _paymentMethod = 'Cash on Delivery';

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (_authService.isAuthenticated && _authService.currentUser != null) {
      final user = _authService.currentUser!;
      setState(() {
        _fullName =
            '${user['FirstName'] ?? ''} ${user['LastName'] ?? ''}'.trim();
        _phone = user['PhoneNumber'] ?? '';
        _address = user['Address'] ?? '';
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create full address from form fields
      final fullAddress = '$_address, $_city $_zipCode';

      // Handle different payment methods
      if (_paymentMethod == 'PayPal') {
        await _processPayPalPayment(fullAddress);
      } else {
        // Process order with standard payment methods
        final result = await OrderService.createOrder(
          paymentMethod: _paymentMethod,
          shippingAddress: fullAddress,
          notes: 'Ordered from mobile app',
        );

        if (result['success']) {
          // Navigate to success page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OrderSuccessPage(
                      orderId: result['orderId']?.toString(),
                    ),
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = result['message'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to process order: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Custom Payment Method Card Widget
  Widget _buildPaymentMethodCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? description,
  }) {
    // Get description based on payment method
    String desc = description ?? _getPaymentMethodDescription(title);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary.withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColor.primary.withAlpha(70)
                      : Colors.black.withAlpha(10),
              blurRadius: isSelected ? 12 : 4,
              spreadRadius: isSelected ? 1 : 0,
              offset: isSelected ? const Offset(0, 5) : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment Method Icon with Animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColor.primary : AppColor.lightGrey,
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppColor.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payment Method Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColor.primary : AppColor.dark,
              ),
            ),

            // Description
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppColor.grey),
              ),
            ],

            // Selection Indicator
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 40 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColor.primary : AppColor.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get payment method descriptions
  String _getPaymentMethodDescription(String method) {
    switch (method) {
      case 'Cash on Delivery':
        return 'Pay when you receive your books';
      case 'PayPal':
        return 'Fast & secure online payment';
      default:
        return '';
    }
  }

  Future<void> _processPayPalPayment(String fullAddress) async {
    try {
      // First create an order with PayPal as payment method
      final orderResult = await OrderService.createOrderForPayPal(
        shippingAddress: fullAddress,
        notes: 'Ordered from mobile app via PayPal',
      );

      if (!orderResult['success']) {
        if (mounted) {
          setState(() {
            _errorMessage = orderResult['message'];
            _isLoading = false;
          });
        }
        return;
      }

      final orderId = orderResult['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to get order ID';
            _isLoading = false;
          });
        }
        return;
      }

      // Get order details
      final orderDetails = await OrderService.getOrderDetails(orderId);
      if (orderDetails == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to get order details';
            _isLoading = false;
          });
        }
        return;
      }

      // Create PayPal payment
      final paymentResult = await PayPalService.createPayment(
        order: orderDetails,
        returnUrl: AppConfig.paypalReturnUrl,
        cancelUrl: AppConfig.paypalCancelUrl,
      );

      if (!paymentResult['success']) {
        if (mounted) {
          setState(() {
            _errorMessage = paymentResult['message'];
            _isLoading = false;
          });
        }
        return;
      }

      final approvalUrl = paymentResult['approvalUrl'];
      final paymentId = paymentResult['paymentId'];

      if (approvalUrl == null || paymentId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to get PayPal approval URL';
            _isLoading = false;
          });
        }
        return;
      }

      // Navigate to PayPal checkout page
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PayPalCheckoutPage(
                  order: orderDetails,
                  approvalUrl: approvalUrl,
                  paymentId: paymentId,
                ),
          ),
        );

        // Handle result from PayPal checkout
        if (result != null && result is Map<String, dynamic>) {
          if (!result['success']) {
            if (mounted) {
              setState(() {
                _errorMessage = result['message'];
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'PayPal payment error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Checkout',
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
          icon: const Icon(Icons.arrow_back, color: AppColor.dark),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: AppColor.primarySoft,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColor.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${CartService.itemCount} items',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColor.dark,
                                ),
                              ),
                              Text(
                                '\$${CartService.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shipping',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColor.dark,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    color: AppColor.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Free',
                                    style: TextStyle(
                                      color: AppColor.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              color: AppColor.border,
                              thickness: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '\$${CartService.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message if any
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Shipping Information
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                color: AppColor.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Shipping Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Full Name Field
                          TextFormField(
                            initialValue: _fullName,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColor.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                            onSaved: (value) => _fullName = value ?? '',
                          ),
                          const SizedBox(height: 16),

                          // Address Field
                          TextFormField(
                            initialValue: _address,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(
                                Icons.home_outlined,
                                color: AppColor.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                            onSaved: (value) => _address = value ?? '',
                          ),
                          const SizedBox(height: 16),

                          // City and ZIP Code Fields
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'City',
                                    prefixIcon: Icon(
                                      Icons.location_city,
                                      color: AppColor.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColor.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColor.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter city';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _city = value ?? '',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'ZIP Code',
                                    prefixIcon: Icon(
                                      Icons.pin_drop_outlined,
                                      color: AppColor.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColor.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColor.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter ZIP code';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _zipCode = value ?? '',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          TextFormField(
                            initialValue: _phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: AppColor.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                            onSaved: (value) => _phone = value ?? '',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payment,
                                color: AppColor.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Custom Payment Method Selection
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Cash on Delivery Option
                              SizedBox(
                                width: 160,
                                child: _buildPaymentMethodCard(
                                  title: 'Cash on Delivery',
                                  icon: Icons.local_shipping_outlined,
                                  isSelected:
                                      _paymentMethod == 'Cash on Delivery',
                                  onTap: () {
                                    setState(() {
                                      _paymentMethod = 'Cash on Delivery';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),

                              // PayPal Option
                              SizedBox(
                                width: 160,
                                child: _buildPaymentMethodCard(
                                  title: 'PayPal',
                                  icon: Icons.account_balance_wallet,
                                  isSelected: _paymentMethod == 'PayPal',
                                  onTap: () {
                                    setState(() {
                                      _paymentMethod = 'PayPal';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Place Order Button
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton(
                        onPressed: _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: AppColor.primary.withAlpha(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_checkout,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Place Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
