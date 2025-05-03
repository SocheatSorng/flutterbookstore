import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../services/cart_service.dart';

class OrderSummaryCard extends StatefulWidget {
  final VoidCallback onCheckout;
  final bool isEnabled;

  const OrderSummaryCard({
    super.key,
    required this.onCheckout,
    this.isEnabled = true,
  });

  @override
  _OrderSummaryCardState createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<OrderSummaryCard> with SingleTickerProviderStateMixin {
  bool _isPromoExpanded = false;
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;
  String? _promoError;
  String? _promoSuccess;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _togglePromoExpansion() {
    setState(() {
      _isPromoExpanded = !_isPromoExpanded;
      if (_isPromoExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _applyPromoCode() async {
    if (_promoController.text.isEmpty) {
      setState(() {
        _promoError = 'Please enter a promo code';
        _promoSuccess = null;
      });
      return;
    }

    setState(() {
      _isApplyingPromo = true;
      _promoError = null;
      _promoSuccess = null;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    // For demo purposes, let's just check if the code is "BOOK10"
    if (_promoController.text.toUpperCase() == 'BOOK10') {
      setState(() {
        _isApplyingPromo = false;
        _promoSuccess = 'Promo code applied successfully!';
      });
    } else {
      setState(() {
        _isApplyingPromo = false;
        _promoError = 'Invalid promo code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = CartService.totalPrice;
    final double shipping = 0.0; // Free shipping
    final double discount = _promoSuccess != null ? (subtotal * 0.1) : 0.0; // 10% discount if promo applied
    final double total = subtotal - discount + shipping;

    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.dark,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${CartService.itemCount} items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          
          // Promo Code Section
          InkWell(
            onTap: _togglePromoExpansion,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.discount_outlined,
                    color: AppColor.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Apply Promo Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    _isPromoExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColor.grey,
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Promo Code Input
          SizeTransition(
            sizeFactor: _animation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            hintStyle: TextStyle(color: AppColor.grey, fontSize: 14),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColor.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColor.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColor.primary),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isApplyingPromo ? null : _applyPromoCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isApplyingPromo
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Apply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                  if (_promoError != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        _promoError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_promoSuccess != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _promoSuccess!,
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          Divider(height: 1),
          
          // Price Details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Subtotal
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
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.dark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                
                // Discount (if promo applied)
                if (_promoSuccess != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount (10%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '-\$${discount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                
                // Shipping
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
                SizedBox(height: 16),
                
                // Divider
                Divider(color: AppColor.border),
                SizedBox(height: 16),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColor.dark,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.isEnabled ? widget.onCheckout : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: AppColor.primary.withOpacity(0.4),
                    ),
                    child: Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
