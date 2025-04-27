import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../views/screens/order_details_page.dart';

class OrderSuccessPage extends StatefulWidget {
  final String? orderId;

  const OrderSuccessPage({
    Key? key,
    this.orderId,
  }) : super(key: key);

  @override
  _OrderSuccessPageState createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    print('OrderSuccessPage initialized with orderId: ${widget.orderId}');

    // Set up animation for success icon
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            // Animated Success Icon
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      margin: EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColor.primarySoft.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: AppColor.primary,
                        size: 120,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Title
            Text(
              'Order Success!',
              style: TextStyle(
                color: AppColor.secondary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'poppins',
              ),
            ),
            SizedBox(height: 8),
            // Order ID
            if (widget.orderId != null && widget.orderId!.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.primarySoft.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Order ID: ${widget.orderId}',
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: 16),
            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Your order has been placed successfully and will be on its way soon!',
                style: TextStyle(
                  color: AppColor.secondary.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 32),
            // Continue Shopping Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
            ),
            SizedBox(height: 16),
            // View Order Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              width: MediaQuery.of(context).size.width,
              child: OutlinedButton(
                onPressed: () {
                  if (widget.orderId != null && widget.orderId!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(orderId: widget.orderId!),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order ID not available'),
                        backgroundColor: AppColor.primary,
                      ),
                    );
                  }
                },
                child: Text(
                  'Track Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColor.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
