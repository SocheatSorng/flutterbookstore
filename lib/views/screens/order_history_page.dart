import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constant/app_color.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../views/screens/order_details_page.dart';
import '../../views/widgets/main_app_bar_widget.dart';
import 'package:flutterbookstore/services/cart_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  bool _isLoading = true;
  List<Order> _orders = [];
  String _errorMessage = '';
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (mounted) {
      await CartService.fetchCartItems();
      setState(() {
        _cartItemCount = CartService.itemCount;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orders = await OrderService.getOrderHistory();
      print('Loaded ${orders.length} orders on the order history page');

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(cartValue: _cartItemCount, showBackButton: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Order History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColor.dark,
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          else if (_orders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColor.grey,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No orders yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColor.dark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you place orders, they will appear here',
                      style: TextStyle(color: AppColor.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Browse Books',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Format date
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(order.orderDate);

    // Status color
    Color statusColor;
    switch (order.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'shipping':
      case 'shipped':
        statusColor = Colors.blue;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColor.dark,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(color: AppColor.grey, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                style: TextStyle(color: AppColor.dark),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(color: AppColor.grey, fontSize: 14),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.payment_outlined, size: 16, color: AppColor.grey),
                  SizedBox(width: 4),
                  Text(
                    order.paymentMethod,
                    style: TextStyle(color: AppColor.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
