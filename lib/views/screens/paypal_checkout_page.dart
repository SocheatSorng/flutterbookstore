import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constant/app_color.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/paypal_service.dart';
import 'order_success_page.dart';

class PayPalCheckoutPage extends StatefulWidget {
  final Order order;
  final String approvalUrl;
  final String paymentId;

  const PayPalCheckoutPage({
    super.key,
    required this.order,
    required this.approvalUrl,
    required this.paymentId,
  });

  @override
  _PayPalCheckoutPageState createState() => _PayPalCheckoutPageState();
}

class _PayPalCheckoutPageState extends State<PayPalCheckoutPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _checkReturnTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    } else {
      _handleWebPlatform();
    }
  }

  @override
  void dispose() {
    _checkReturnTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                // Handle PayPal return and cancel URLs
                if (request.url.startsWith('flutterbookstore://paypalpay')) {
                  _handlePayPalReturn(request.url);
                  return NavigationDecision.prevent;
                } else if (request.url.startsWith(
                  'flutterbookstore://cancel',
                )) {
                  _handlePayPalCancel();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _errorMessage = 'Error loading PayPal: ${error.description}';
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  Future<void> _handleWebPlatform() async {
    try {
      // For web platform, open PayPal in the same window
      final Uri url = Uri.parse(widget.approvalUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          webOnlyWindowName: '_self', // Open in same window
          mode: LaunchMode.platformDefault,
        );

        // Start checking for return periodically
        _checkReturnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final currentUrl = Uri.base.toString();

          // Check for PayPal return parameters in the URL
          if (currentUrl.contains('paymentId=') &&
              currentUrl.contains('PayerID=')) {
            timer.cancel();
            _handlePayPalReturn(currentUrl);
          }
          // Check for custom URL schemes (which won't work directly in web)
          else if (currentUrl.contains('flutterbookstore://paypalpay')) {
            timer.cancel();
            _handlePayPalReturn(currentUrl);
          } else if (currentUrl.contains('flutterbookstore://cancel') ||
              currentUrl.contains('paypal-cancel.html')) {
            timer.cancel();
            _handlePayPalCancel();
          }
          // Check for return to main page after successful payment
          else if (currentUrl.endsWith('/') &&
              !currentUrl.contains('paypal') &&
              !url.toString().startsWith(currentUrl)) {
            // We might have returned from PayPal - check localStorage
            timer.cancel();

            // The actual handling will be done by the main.dart code
            // that checks for PayPal return data in localStorage
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Could not launch PayPal checkout';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error launching PayPal: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePayPalReturn(String url) async {
    print('Handling PayPal return URL: $url');

    // Parse URL parameters
    final uri = Uri.parse(url);
    final paymentId = uri.queryParameters['paymentId'];
    final payerId = uri.queryParameters['PayerID'];
    final token = uri.queryParameters['token'];

    print(
      'PayPal return parameters - paymentId: $paymentId, payerId: $payerId, token: $token',
    );

    if (payerId != null && paymentId != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        print('Executing PayPal payment...');
        // Execute PayPal payment
        final result = await PayPalService.executePayment(
          paymentId: paymentId,
          payerId: payerId,
        );

        print(
          'PayPal payment execution result: ${result['success']} - ${result['message']}',
        );

        if (result['success']) {
          print('Payment successful, updating order: ${widget.order.id}');
          // Update order with payment information
          final updateResult = await OrderService.updateOrderPayment(
            orderId: widget.order.id,
            paymentId: paymentId,
            payerId: payerId,
            token: token ?? '',
            status: 'completed',
          );

          print(
            'Order update result: ${updateResult['success']} - ${updateResult['message']}',
          );

          if (updateResult['success']) {
            // Clear any previous errors
            if (mounted) {
              setState(() {
                _errorMessage = '';
              });
            }

            print(
              'Navigating to order success page with orderId: ${widget.order.id}',
            );
            // Navigate to success page
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => OrderSuccessPage(orderId: widget.order.id),
                ),
              );
            }
          } else {
            print('Failed to update order: ${updateResult['message']}');
            if (mounted) {
              setState(() {
                _errorMessage = updateResult['message'];
                _isLoading = false;
              });
            }
          }
        } else {
          print('Payment execution failed: ${result['message']}');
          if (mounted) {
            setState(() {
              _errorMessage = result['message'];
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Exception during payment processing: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Error processing payment: $e';
            _isLoading = false;
          });
        }
      }
    } else {
      print('Invalid PayPal response: missing payerId or paymentId');
      setState(() {
        _errorMessage = 'Invalid PayPal response';
        _isLoading = false;
      });
    }
  }

  void _handlePayPalCancel() {
    Navigator.pop(context, {
      'success': false,
      'message': 'Payment cancelled by user',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Checkout'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, {
              'success': false,
              'message': 'Payment cancelled by user',
            });
          },
        ),
      ),
      body: Stack(
        children: [
          if (kIsWeb)
            const Center(
              child: Text(
                'Processing PayPal payment...\nPlease complete the payment in the opened window.',
              ),
            )
          else if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                ),
              ),
            ),
          if (_errorMessage.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'success': false,
                          'message': _errorMessage,
                        });
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
