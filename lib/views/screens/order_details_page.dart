import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constant/app_color.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../views/widgets/main_app_bar_widget.dart';
import 'package:flutterbookstore/services/cart_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isLoading = true;
  Order? _order;
  String _errorMessage = '';
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _loadCartItems();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final order = await OrderService.getOrderDetails(widget.orderId);
      if (order != null) {
        print(
          'Loaded order details for order ID: ${order.id} with ${order.items.length} items',
        );
      } else {
        print('No order details found for ID: ${widget.orderId}');
      }

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCartItems() async {
    if (mounted) {
      await CartService.fetchCartItems();
      setState(() {
        _cartItemCount = CartService.itemCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(cartValue: _cartItemCount, showBackButton: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
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
                      onPressed: _loadOrderDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              )
              : _order == null
              ? Center(child: Text('Order not found'))
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    final order = _order!;
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final formattedDate = dateFormat.format(order.orderDate);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColor.dark,
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          SizedBox(height: 8),

          // Order Date
          Text(
            'Placed on $formattedDate',
            style: TextStyle(color: AppColor.grey, fontSize: 14),
          ),
          SizedBox(height: 24),

          // Delivery Information
          _buildSectionTitle('Delivery Information'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColor.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppColor.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColor.dark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    order.deliveryAddress,
                    style: TextStyle(color: AppColor.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Payment Information
          _buildSectionTitle('Payment Information'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColor.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        color: AppColor.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColor.dark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    order.paymentMethod,
                    style: TextStyle(color: AppColor.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Order Items
          _buildSectionTitle('Order Items (${order.items.length})'),

          // Order Items List
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              return _buildOrderItemCard(order.items[index]);
            },
          ),
          SizedBox(height: 24),

          // Order Summary
          _buildSectionTitle('Order Summary'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColor.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Subtotal',
                    '\$${_calculateSubtotal(order).toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow('Shipping Fee', '\$0.00'),
                  _buildSummaryRow(
                    'Tax',
                    '\$${(_calculateSubtotal(order) * 0.05).toStringAsFixed(2)}',
                  ),
                  Divider(),
                  _buildSummaryRow(
                    'Total',
                    '\$${order.total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColor.dark,
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    // Determine image source
    Widget imageWidget;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      if (item.imageUrl!.startsWith('assets/')) {
        // Local asset image
        imageWidget = Image.asset(item.imageUrl!, fit: BoxFit.cover);
      } else {
        // Network image with error handling
        imageWidget = Image.network(
          item.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Center(child: Icon(Icons.book, color: AppColor.grey));
          },
        );
      }
    } else {
      // No image available
      imageWidget = Center(child: Icon(Icons.book, color: AppColor.grey));
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColor.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageWidget,
            ),
            SizedBox(width: 12),
            // Book Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColor.dark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Quantity: ${item.quantity}',
                    style: TextStyle(color: AppColor.grey, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColor.dark,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColor.dark : AppColor.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppColor.primary : AppColor.dark,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal(Order order) {
    return order.items.fold(0, (sum, item) => sum + item.subtotal);
  }
}
