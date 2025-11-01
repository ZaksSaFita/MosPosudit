import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:mosposudit_shared/services/payment_service.dart';
import 'package:mosposudit_shared/services/order_service.dart';
import 'package:mosposudit_shared/dtos/payment/paypal_order_response.dart';
import 'package:mosposudit_shared/dtos/order/order_insert_request.dart';
import 'package:mosposudit_shared/services/cart_service.dart';
import 'dart:async';
import '../../main.dart';

class PayPalPaymentScreen extends StatefulWidget {
  final OrderInsertRequest orderData;

  const PayPalPaymentScreen({super.key, required this.orderData});

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  final _paymentService = PaymentService();
  final _orderService = OrderService();
  final _cartService = CartService();
  WebViewController? _controller;
  bool _isLoading = true;
  String? _approvalUrl;
  bool _paymentCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePayPal();
  }

  Future<void> _initializePayPal() async {
    try {
      if (kDebugMode) {
        print('Initializing PayPal payment...');
        print('Order data: ${widget.orderData.toJson()}');
      }

      // Create PayPal order (without creating order in database yet)
      final paypalOrder = await _paymentService.createPayPalOrder(widget.orderData);
      
      if (kDebugMode) {
        print('PayPal order created: ${paypalOrder.orderId}');
        print('Approval URL: ${paypalOrder.approvalUrl}');
      }

      if (paypalOrder.approvalUrl.isEmpty) {
        throw Exception('PayPal approval URL is empty');
      }

      setState(() {
        _approvalUrl = paypalOrder.approvalUrl;
        _errorMessage = null;
      });

      // Initialize webview with platform-specific configuration
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (kDebugMode) {
                print('Page started loading: $url');
              }
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) {
              if (kDebugMode) {
                print('Page finished loading: $url');
              }
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (kDebugMode) {
                print('WebView error: ${error.description}');
                print('Error code: ${error.errorCode}');
                print('Error type: ${error.errorType}');
              }
              // Handle WebView errors gracefully
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'WebView error: ${error.description}';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('WebView error: ${error.description}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              if (kDebugMode) {
                print('Navigation to: $url');
              }
              
              // Check if this is the return URL
              if (url.contains('/payment/paypal/return')) {
                // Extract PayPal Order ID from URL
                // PayPal returns Order ID as 'token' parameter, but sometimes as 'order_id'
                try {
                  final uri = Uri.parse(url);
                  final token = uri.queryParameters['token'] ?? uri.queryParameters['order_id'];
                  
                  if (token != null && token.isNotEmpty) {
                    _handlePayPalReturn(token);
                  } else {
                    if (kDebugMode) {
                      print('Warning: No token or order_id found in PayPal return URL: $url');
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Error parsing return URL: $e');
                  }
                }
                
                // Don't navigate to this URL in webview
                return NavigationDecision.prevent;
              }
              
              // Check if this is the cancel URL
              if (url.contains('/payment/paypal/cancel')) {
                _handlePayPalCancel();
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        );

      // Platform-specific Android configuration to prevent crashes
      if (_controller!.platform is AndroidWebViewController) {
        final androidController = _controller!.platform as AndroidWebViewController;
        AndroidWebViewController.enableDebugging(kDebugMode);
        androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      // Load the PayPal approval URL
      await _controller!.loadRequest(Uri.parse(_approvalUrl!));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error initializing PayPal: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing PayPal: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handlePayPalReturn(String token) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Handle return - backend will capture the order
      final result = await _paymentService.handlePayPalReturn(token);
      
      if (result != null && result['success'] == true) {
        // Clear cart after successful payment (order is now created in database)
        try {
          await _cartService.clearCart();
        } catch (e) {
          print('Error clearing cart: $e');
        }

        setState(() {
          _paymentCompleted = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Payment completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Wait a bit before navigating to show success message
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            // Pop all routes back to ClientHomeScreen
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // After popping, switch to Orders tab using the GlobalKey
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final homeState = ClientHomeScreen.navigatorKey.currentState;
              if (homeState != null) {
                homeState.switchToOrders();
              }
            });
          }
        }
      } else {
        throw Exception(result?['message'] ?? 'Payment was not completed');
      }
    } catch (e) {
      print('Error handling PayPal return: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Extract the actual error message from exception
        String errorMessage = 'Payment was not completed';
        if (e.toString().contains('Exception:')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handlePayPalCancel() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _errorMessage == null && _approvalUrl == null
          ? const Center(child: CircularProgressIndicator())
          : _paymentCompleted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'Payment Completed!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('You will receive a confirmation email shortly.'),
                    ],
                  ),
                )
              : _errorMessage != null || _approvalUrl == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 80, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Error loading PayPal',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage ?? 'Failed to create PayPal order',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                  _isLoading = true;
                                  _approvalUrl = null;
                                });
                                _initializePayPal();
                              },
                              child: const Text('Retry'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SafeArea(
                      child: Stack(
                        children: [
                          WebViewWidget(controller: _controller!),
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
    );
  }
}

