class Payment {
  final String id;
  final String orderId;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final String? transactionId;
  final DateTime paymentDate;
  final Map<String, dynamic>? paymentDetails;

  Payment({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionId,
    required this.paymentDate,
    this.paymentDetails,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      transactionId: json['transactionId'],
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : DateTime.now(),
      paymentDetails: json['paymentDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'currency': currency,
      'status': status,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentDetails': paymentDetails,
    };
  }
}

class PayPalPaymentDetails {
  final String payerId;
  final String paymentId;
  final String token;
  final String status;

  PayPalPaymentDetails({
    required this.payerId,
    required this.paymentId,
    required this.token,
    required this.status,
  });

  factory PayPalPaymentDetails.fromJson(Map<String, dynamic> json) {
    return PayPalPaymentDetails(
      payerId: json['payerId'] ?? '',
      paymentId: json['paymentId'] ?? '',
      token: json['token'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payerId': payerId,
      'paymentId': paymentId,
      'token': token,
      'status': status,
    };
  }
}
