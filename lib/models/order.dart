class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String status; // e.g., 'pending', 'completed', 'cancelled'
  final String paymentMethod;
  final String deliveryAddress;
  final DateTime orderDate;
  final DateTime? deliveryDate;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.orderDate,
    this.deliveryDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats
    final String orderId = json['OrderID'] ?? json['orderId'] ?? json['id'] ?? '';
    final String userId = json['AccountID'] ?? json['userId'] ?? '';
    final double total = (json['OrderTotal'] ?? json['total'] ?? 0).toDouble();
    final String status = json['Status'] ?? json['status'] ?? 'Pending';
    final String paymentMethod = json['PaymentMethod'] ?? json['paymentMethod'] ?? '';
    final String deliveryAddress = json['ShippingAddress'] ?? json['deliveryAddress'] ?? '';
    
    // Parse date
    DateTime orderDate;
    try {
      final dateStr = json['OrderDate'] ?? json['orderDate'] ?? DateTime.now().toString();
      orderDate = DateTime.parse(dateStr);
    } catch (_) {
      orderDate = DateTime.now();
    }

    // Parse order items
    List<OrderItem> items = [];
    if (json['OrderItems'] != null || json['items'] != null) {
      final itemsList = json['OrderItems'] ?? json['items'] ?? [];
      items = List<OrderItem>.from(
        itemsList.map((item) => OrderItem.fromJson(item))
      );
    }

    return Order(
      id: orderId,
      userId: userId,
      items: items,
      total: total,
      status: status,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      orderDate: orderDate,
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
    };
  }
}

class OrderItem {
  final String bookId;
  final String title;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.bookId,
    required this.title,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      bookId: (json['BookID'] ?? json['bookId'] ?? '').toString(),
      title: json['Title'] ?? json['title'] ?? '',
      price: (json['Price'] ?? json['price'] ?? 0).toDouble(),
      quantity: json['Quantity'] ?? json['quantity'] ?? 1,
      imageUrl: json['ImageUrl'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  double get subtotal => price * quantity;
} 