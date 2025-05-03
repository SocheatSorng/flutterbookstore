import 'package:flutter/material.dart';
import '../../constant/app_color.dart';

class EmptyCartView extends StatefulWidget {
  final VoidCallback onStartShopping;
  final VoidCallback onRefresh;

  const EmptyCartView({
    super.key,
    required this.onStartShopping,
    required this.onRefresh,
  });

  @override
  _EmptyCartViewState createState() => _EmptyCartViewState();
}

class _EmptyCartViewState extends State<EmptyCartView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Center(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Empty cart illustration
                    Container(
                      width: 240,
                      height: 240,
                      margin: EdgeInsets.only(bottom: 24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Cart icon
                          Positioned(
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 100,
                              color: AppColor.primary.withOpacity(0.7),
                            ),
                          ),
                          // Small circles animation
                          for (int i = 0; i < 5; i++)
                            Positioned(
                              top: 40 + (i * 30),
                              right: 60 + (i * 10),
                              child: Container(
                                width: 12 - (i * 2),
                                height: 12 - (i * 2),
                                decoration: BoxDecoration(
                                  color: AppColor.secondary.withOpacity(
                                    0.6 - (i * 0.1),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          // Sad face emoji
                          Positioned(
                            bottom: 30,
                            right: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.sentiment_dissatisfied,
                                color: Colors.orange,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title
                    Text(
                      'Your Cart is Empty',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColor.dark,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Description
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Looks like you haven\'t added any books to your cart yet. Explore our collection and find your next favorite read!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColor.grey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Start Shopping Button
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: widget.onStartShopping,
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: Text(
                          'Start Shopping',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Refresh Button
                    TextButton.icon(
                      onPressed: widget.onRefresh,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppColor.primary,
                      ),
                      label: Text(
                        'Refresh Cart',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
