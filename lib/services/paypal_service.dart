import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import '../config/app_config.dart';
import '../models/order.dart';
import '../views/screens/order_success_page.dart';

class PayPalService {
  // Track processed payments to prevent duplicate handling
  static final Set<String> _processedPayments = {};
  static const String _processedPaymentsKey = 'processed_paypal_payments';

  // Initialize processed payments from local storage
  static Future<void> initProcessedPayments() async {
    if (kIsWeb) {
      try {
        // For web platform, we can use localStorage directly through JavaScript
        // This will be handled in paypal-return.html
        // Here we'll just initialize the in-memory set
        _processedPayments.clear();
      } catch (e) {
        print('Error initializing processed payments: $e');
      }
    } else {
      // For mobile platforms, use shared_preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedPayments = prefs.getStringList(_processedPaymentsKey) ?? [];
        _processedPayments.clear();
        _processedPayments.addAll(storedPayments);
        print(
          'Loaded ${_processedPayments.length} processed payments from storage',
        );
      } catch (e) {
        print('Error loading processed payments: $e');
      }
    }
  }

  // Save processed payments to local storage
  static Future<void> saveProcessedPayment(String paymentId) async {
    if (paymentId == null || paymentId.isEmpty) return;

    // Add to in-memory set
    _processedPayments.add(paymentId);

    if (!kIsWeb) {
      // For mobile platforms, use shared_preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _processedPaymentsKey,
          _processedPayments.toList(),
        );
        print('Saved processed payment $paymentId to storage');
      } catch (e) {
        print('Error saving processed payment: $e');
      }
    }
  }

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

      // Add order ID to return and cancel URLs
      final String orderId = order.id;
      String modifiedReturnUrl = returnUrl;
      String modifiedCancelUrl = cancelUrl;

      // For web platform, add order ID to the hash part of the URL
      if (kIsWeb) {
        // If URLs already have a hash, append to it, otherwise add new hash
        if (returnUrl.contains('#')) {
          modifiedReturnUrl = '$returnUrl&order_id=$orderId';
        } else {
          modifiedReturnUrl = '$returnUrl#order_id=$orderId';
        }

        if (cancelUrl.contains('#')) {
          modifiedCancelUrl = '$cancelUrl&order_id=$orderId';
        } else {
          modifiedCancelUrl = '$cancelUrl#order_id=$orderId';
        }
      } else {
        // For mobile, add order ID as a query parameter
        final returnUri = Uri.parse(returnUrl);
        final cancelUri = Uri.parse(cancelUrl);

        modifiedReturnUrl =
            Uri(
              scheme: returnUri.scheme,
              host: returnUri.host,
              path: returnUri.path,
              queryParameters: {
                ...returnUri.queryParameters,
                'order_id': orderId,
              },
            ).toString();

        modifiedCancelUrl =
            Uri(
              scheme: cancelUri.scheme,
              host: cancelUri.host,
              path: cancelUri.path,
              queryParameters: {
                ...cancelUri.queryParameters,
                'order_id': orderId,
              },
            ).toString();
      }

      print('PayPal return URL: $modifiedReturnUrl');
      print('PayPal cancel URL: $modifiedCancelUrl');

      // Store order ID in localStorage for web platform
      if (kIsWeb) {
        try {
          // Store the current order ID in localStorage
          html.window.localStorage['currentOrderId'] = orderId;
          print('Stored current order ID in localStorage: $orderId');
        } catch (e) {
          print('Error storing order ID in localStorage: $e');
        }
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
            'custom': order.id, // Store order ID in custom field
            'invoice_number': order.id, // Store order ID in invoice number
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
        'redirect_urls': {
          'return_url': modifiedReturnUrl,
          'cancel_url': modifiedCancelUrl,
        },
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

      // Extract parameters
      final paymentId = uri.queryParameters['paymentId'];
      final payerId = uri.queryParameters['PayerID'];
      final token = uri.queryParameters['token'];
      final orderId =
          uri.queryParameters['order_id']; // Extract order_id if present

      print(
        'PayPal return parameters - paymentId: $paymentId, payerId: $payerId, token: $token, orderId: $orderId',
      );

      // Initialize processed payments if needed
      await initProcessedPayments();

      // Check if we've already processed this payment to avoid duplicates
      if (paymentId != null) {
        if (_processedPayments.contains(paymentId)) {
          print(
            'Payment $paymentId already processed. Skipping duplicate processing.',
          );
          return;
        }
        // Add to the set of processed payments and persist
        await saveProcessedPayment(paymentId);
      }

      // Check if this is a return URL with proper parameters
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
          // Get the order ID - either from URL or from payment details
          String finalOrderId = orderId ?? '';

          // If we don't have an order ID yet, try to extract it from payment details
          if (finalOrderId.isEmpty) {
            // Get the order ID from the payment details
            final paymentDetails = result['paymentDetails'];
            print('Payment details: $paymentDetails');

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
              finalOrderId = match?.group(1) ?? '';

              print('Extracted order ID from description: $finalOrderId');
            }

            // If we couldn't extract the order ID from the description,
            // try to get it from custom field or invoice number
            if (finalOrderId.isEmpty) {
              if (paymentDetails != null &&
                  paymentDetails['transactions'] != null &&
                  paymentDetails['transactions'].isNotEmpty) {
                // Try invoice number
                final invoiceNumber =
                    paymentDetails['transactions'][0]['invoice_number'];
                if (invoiceNumber != null &&
                    invoiceNumber.toString().isNotEmpty) {
                  finalOrderId = invoiceNumber.toString();
                  print('Using invoice number as order ID: $finalOrderId');
                }

                // Try custom field
                if (finalOrderId.isEmpty) {
                  final custom = paymentDetails['transactions'][0]['custom'];
                  if (custom != null && custom.toString().isNotEmpty) {
                    finalOrderId = custom.toString();
                    print('Using custom field as order ID: $finalOrderId');
                  }
                }
              }
            }
          }

          // Call webhook for web platform to ensure notification is sent
          if (kIsWeb && finalOrderId.isNotEmpty) {
            try {
              print('Calling PayPal webhook for notification...');

              // Construct the webhook URL using the configured API base URL
              final webhookUrl = Uri.parse(
                '${AppConfig.apiBaseUrl}/paypal-webhook',
              );
              print('Webhook URL: $webhookUrl');

              http
                  .post(
                    webhookUrl,
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                      'X-API-Key': AppConfig.apiKey,
                    },
                    body: json.encode({
                      'order_id': finalOrderId,
                      'payment_id': paymentId,
                      'payer_id': payerId,
                      'is_direct_webhook': true,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    }),
                  )
                  .then((response) {
                    print(
                      'Webhook response: ${response.statusCode} - ${response.body}',
                    );
                  })
                  .catchError((error) {
                    print('Webhook error: $error');
                  });
            } catch (e) {
              print('Error calling webhook: $e');
            }
          }

          if (finalOrderId.isNotEmpty) {
            print(
              'Navigating to order success page with orderId: $finalOrderId',
            );

            // Navigate to the success page
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => OrderSuccessPage(orderId: finalOrderId),
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
                              onPressed: () => navigatorKey.currentState?.pop(),
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
