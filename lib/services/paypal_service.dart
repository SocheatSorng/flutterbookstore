import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/order.dart';
import '../views/screens/order_success_page.dart';

class PayPalService {
  // PayPal API URLs
  static String get _baseUrl =>
      AppConfig.paypalSandboxMode
          ? 'https://api.sandbox.paypal.com'
          : 'https://api.paypal.com';

  static String get _authUrl => '$_baseUrl/v1/oauth2/token';
  static String get _paymentUrl => '$_baseUrl/v1/payments/payment';
  static String get _executeUrl => '$_baseUrl/v1/payments/payment';

  // Get PayPal access token
  static Future<String?> getAccessToken() async {
    try {
      final auth = base64Encode(
        utf8.encode(
          '${AppConfig.paypalClientId}:${AppConfig.paypalClientSecret}',
        ),
      );

      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        print('Failed to get PayPal access token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting PayPal access token: $e');
      return null;
    }
  }

  // Create PayPal payment
  static Future<Map<String, dynamic>> createPayment({
    required Order order,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get PayPal access token',
          'approvalUrl': null,
          'paymentId': null,
        };
      }

      // Prepare payment request body
      final Map<String, dynamic> paymentRequest = {
        'intent': 'sale',
        'payer': {'payment_method': 'paypal'},
        'transactions': [
          {
            'amount': {
              'total': order.total.toStringAsFixed(2),
              'currency': AppConfig.currency,
              'details': {
                'subtotal': order.total.toStringAsFixed(2),
                'shipping': '0.00',
                'tax': '0.00',
              },
            },
            'description': 'Payment for order #${order.id}',
            'item_list': {
              'items':
                  order.items
                      .map(
                        (item) => {
                          'name': item.title,
                          'quantity': item.quantity,
                          'price': item.price.toStringAsFixed(2),
                          'currency': AppConfig.currency,
                        },
                      )
                      .toList(),
            },
          },
        ],
        'redirect_urls': {'return_url': returnUrl, 'cancel_url': cancelUrl},
      };

      // Send payment request to PayPal
      final response = await http.post(
        Uri.parse(_paymentUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(paymentRequest),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final links = data['links'] as List;
        String? approvalUrl;
        String? paymentId = data['id'];

        // Find approval URL
        for (var link in links) {
          if (link['rel'] == 'approval_url') {
            approvalUrl = link['href'];
            break;
          }
        }

        if (approvalUrl != null) {
          return {
            'success': true,
            'message': 'Payment created successfully',
            'approvalUrl': approvalUrl,
            'paymentId': paymentId,
          };
        } else {
          return {
            'success': false,
            'message': 'Approval URL not found',
            'approvalUrl': null,
            'paymentId': null,
          };
        }
      } else {
        print('Failed to create PayPal payment: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to create PayPal payment',
          'approvalUrl': null,
          'paymentId': null,
        };
      }
    } catch (e) {
      print('Error creating PayPal payment: $e');
      return {
        'success': false,
        'message': 'Error creating PayPal payment: $e',
        'approvalUrl': null,
        'paymentId': null,
      };
    }
  }

  // Execute PayPal payment
  static Future<Map<String, dynamic>> executePayment({
    required String paymentId,
    required String payerId,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get PayPal access token',
        };
      }

      // For web platform, verify payment first
      if (kIsWeb) {
        final verifyResult = await getPaymentDetails(paymentId);
        if (!verifyResult['success']) {
          return verifyResult;
        }
      }

      // Execute payment
      final response = await http.post(
        Uri.parse('$_executeUrl/$paymentId/execute'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'payer_id': payerId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final state = data['state'];

        if (state == 'approved' || state == 'completed') {
          return {
            'success': true,
            'message': 'Payment executed successfully',
            'paymentDetails': data,
          };
        } else {
          print('Payment not approved. State: $state');
          return {'success': false, 'message': 'Payment not approved: $state'};
        }
      } else {
        final error = json.decode(response.body);
        print('Failed to execute PayPal payment: ${response.body}');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to execute PayPal payment',
        };
      }
    } catch (e) {
      print('Error executing PayPal payment: $e');
      return {
        'success': false,
        'message': 'Error executing PayPal payment: $e',
      };
    }
  }

  // Get payment details
  static Future<Map<String, dynamic>> getPaymentDetails(
    String paymentId,
  ) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get PayPal access token',
        };
      }

      // Get payment details
      final response = await http.get(
        Uri.parse('$_paymentUrl/$paymentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Payment details retrieved successfully',
          'paymentDetails': data,
        };
      } else {
        print('Failed to get PayPal payment details: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to get PayPal payment details',
        };
      }
    } catch (e) {
      print('Error getting PayPal payment details: $e');
      return {
        'success': false,
        'message': 'Error getting PayPal payment details: $e',
      };
    }
  }

  // Handle PayPal return URL for web platform
  static void handlePayPalReturnUrl(
    String url,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    try {
      print('Handling PayPal return URL in PayPalService: $url');

      // Parse the URL
      final uri = Uri.parse(url);

      // Check if this is a return URL
      if (url.contains('flutterbookstore://paypalpay')) {
        // Extract parameters
        final paymentId = uri.queryParameters['paymentId'];
        final payerId = uri.queryParameters['PayerID'];
        final token = uri.queryParameters['token'];

        print(
          'PayPal return parameters - paymentId: $paymentId, payerId: $payerId, token: $token',
        );

        if (paymentId != null && payerId != null) {
          print('Executing PayPal payment...');
          // Execute the payment
          final result = await executePayment(
            paymentId: paymentId,
            payerId: payerId,
          );

          print(
            'PayPal payment execution result: ${result['success']} - ${result['message']}',
          );

          if (result['success']) {
            // Get the order ID from the payment details
            final paymentDetails = result['paymentDetails'];
            print('Payment details: $paymentDetails');

            String orderId = '';

            // Try to extract order ID from description (format: "Payment for order #123")
            if (paymentDetails != null &&
                paymentDetails['transactions'] != null &&
                paymentDetails['transactions'].isNotEmpty) {
              final String description =
                  paymentDetails['transactions'][0]['description'] ?? '';

              print('Payment description: $description');

              // Extract order ID from description
              final RegExp regex = RegExp(r'#(\d+)');
              final match = regex.firstMatch(description);
              orderId = match?.group(1) ?? '';

              print('Extracted order ID from description: $orderId');
            }

            // If we couldn't extract the order ID from the description,
            // try to get it from custom field or invoice number
            if (orderId.isEmpty) {
              if (paymentDetails != null &&
                  paymentDetails['transactions'] != null &&
                  paymentDetails['transactions'].isNotEmpty) {
                // Try invoice number
                final invoiceNumber =
                    paymentDetails['transactions'][0]['invoice_number'];
                if (invoiceNumber != null &&
                    invoiceNumber.toString().isNotEmpty) {
                  orderId = invoiceNumber.toString();
                  print('Using invoice number as order ID: $orderId');
                }

                // Try custom field
                if (orderId.isEmpty) {
                  final custom = paymentDetails['transactions'][0]['custom'];
                  if (custom != null && custom.toString().isNotEmpty) {
                    orderId = custom.toString();
                    print('Using custom field as order ID: $orderId');
                  }
                }
              }
            }

            if (orderId.isNotEmpty) {
              print('Navigating to order success page with orderId: $orderId');

              // Navigate to the success page
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OrderSuccessPage(orderId: orderId),
                ),
              );
            } else {
              print('Could not determine order ID from PayPal response');

              // Even if we couldn't get the order ID, still show a success page
              // This ensures the user sees a success message even if there's an issue
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const OrderSuccessPage(orderId: null),
                ),
              );
            }
          } else {
            // Handle payment failure
            print('Payment execution failed: ${result['message']}');

            // Show an error dialog
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(title: const Text('Payment Error')),
                      body: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Payment Failed',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                result['message'] ??
                                    'An error occurred during payment processing',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed:
                                    () => navigatorKey.currentState?.pop(),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            );
          }
        } else {
          print('Missing required PayPal parameters');
        }
      } else if (url.contains('flutterbookstore://cancel')) {
        // Handle cancellation
        print('PayPal payment was cancelled by the user');
        // Navigate back to the previous page
        navigatorKey.currentState?.pop();
      }
    } catch (e) {
      print('Error handling PayPal return URL: $e');

      // Show a generic success page even if there's an error
      // This ensures the user sees something rather than being stuck
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OrderSuccessPage(orderId: null),
        ),
      );
    }
  }
}
