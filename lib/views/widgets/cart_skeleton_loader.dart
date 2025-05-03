import 'package:flutter/material.dart';

class CartSkeletonLoader extends StatefulWidget {
  const CartSkeletonLoader({super.key});

  @override
  _CartSkeletonLoaderState createState() => _CartSkeletonLoaderState();
}

class _CartSkeletonLoaderState extends State<CartSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Cart items skeletons
            for (int i = 0; i < 3; i++)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image skeleton
                    Container(
                      width: 90,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.withOpacity(_animation.value),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Content skeleton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title skeleton
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.withOpacity(_animation.value),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Shorter title line
                          Container(
                            height: 16,
                            width: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.withOpacity(_animation.value),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Price skeleton
                          Container(
                            height: 20,
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.withOpacity(_animation.value),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Bottom row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total price skeleton
                              Container(
                                height: 16,
                                width: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.withOpacity(
                                    _animation.value,
                                  ),
                                ),
                              ),
                              // Quantity controls skeleton
                              Container(
                                height: 32,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.withOpacity(
                                    _animation.value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Order summary skeleton
            Container(
              margin: EdgeInsets.only(top: 16, bottom: 24),
              padding: EdgeInsets.all(16),
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
                  // Header skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.withOpacity(_animation.value),
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.withOpacity(_animation.value),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),

                  // Price rows skeletons
                  for (int i = 0; i < 3; i++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.withOpacity(_animation.value),
                          ),
                        ),
                        Container(
                          height: 14,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.withOpacity(_animation.value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                  ],

                  SizedBox(height: 8),
                  Divider(),
                  SizedBox(height: 16),

                  // Total row skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 20,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.withOpacity(_animation.value),
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.withOpacity(_animation.value),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Button skeleton
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.withOpacity(_animation.value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
