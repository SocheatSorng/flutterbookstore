import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constant/app_color.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
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
        _fullName = '${user['FirstName'] ?? ''} ${user['LastName'] ?? ''}'.trim();
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

      // Process order
      final result = await OrderService.createOrder(
        paymentMethod: _paymentMethod,
        shippingAddress: fullAddress,
        notes: 'Ordered from mobile app',
      );

      if (result['success']) {
        // Navigate to success page
        try {
          print('Navigating to OrderSuccessPage with orderId: ${result['orderId']}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSuccessPage(
                orderId: result['orderId']?.toString(),
              ),
            ),
          );
        } catch (e) {
          print('Error navigating to OrderSuccessPage: $e');
          setState(() {
            _errorMessage = 'Error displaying order success page: $e';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process order: $e';
        _isLoading = false;
      });
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
        title: Text(
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Order Summary
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColor.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${CartService.itemCount} items'),
                            Text('\$${CartService.totalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shipping'),
                            Text(
                              'Free',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${CartService.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColor.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Error message if any
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  // Shipping Information
                  Text(
                    'Shipping Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    initialValue: _fullName,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                    onSaved: (value) => _fullName = value ?? '',
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    initialValue: _address,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                    onSaved: (value) => _address = value ?? '',
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'ZIP Code',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                  SizedBox(height: 16),
                  TextFormField(
                    initialValue: _phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                  SizedBox(height: 24),

                  // Payment Method
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColor.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('Cash on Delivery'),
                          value: 'Cash on Delivery',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: AppColor.primary,
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Text('Credit Card'),
                          value: 'Credit Card',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: AppColor.primary,
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Text('PayPal'),
                          value: 'PayPal',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: AppColor.primary,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Place Order Button
                  ElevatedButton(
                    onPressed: _submitOrder,
                    child: Text(
                      'Place Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 