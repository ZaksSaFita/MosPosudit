import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:mosposudit_shared/services/payment_service.dart';
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final paypalOrder = await _paymentService.createPayPalOrder(widget.orderData).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Payment request timed out. Please check your internet connection and try again.');
        },
      );

      if (paypalOrder.approvalUrl.isEmpty) {
        throw Exception('PayPal approval URL is empty');
      }

      setState(() {
        _approvalUrl = paypalOrder.approvalUrl;
        _errorMessage = null;
      });

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _enableKeyboardSupport();
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.connect ||
                  error.errorType == WebResourceErrorType.timeout) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Unable to connect to PayPal. Please check your internet connection.';
                  });
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              
              if (url.contains('/payment/paypal/return')) {
                final uri = Uri.parse(url);
                final token = uri.queryParameters['token'] ?? uri.queryParameters['order_id'];
                
                if (token != null && token.isNotEmpty) {
                  _handlePayPalReturn(token);
                }
                
                return NavigationDecision.prevent;
              }
              
              if (url.contains('/payment/paypal/cancel')) {
                _handlePayPalCancel();
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        );

      if (_controller!.platform is AndroidWebViewController) {
        final androidController = _controller!.platform as AndroidWebViewController;
        AndroidWebViewController.enableDebugging(kDebugMode);
        androidController.setMediaPlaybackRequiresUserGesture(false);
        androidController.setOnShowFileSelector((params) async => []);
      }
      
      _controller!.enableZoom(true);
      _controller!.setBackgroundColor(Colors.white);
      await _controller!.loadRequest(Uri.parse(_approvalUrl!));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
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

      final result = await _paymentService.handlePayPalReturn(token);
      
      if (result != null && result['success'] == true) {
        try {
          await _cartService.clearCart();
        } catch (e) {
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

          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final homeState = ClientHomeScreen.navigatorKey.currentState;
              if (homeState != null) {
                homeState.switchToHome();
              }
            });
          }
        }
      } else {
        throw Exception(result?['message'] ?? 'Payment was not completed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
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

  Future<void> _enableKeyboardSupport() async {
    if (_controller == null) return;
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      await _controller!.runJavaScript('''
        (function() {
          function tryAutoFill() {
            try {
              var emailInput = document.querySelector('input[type="email"]');
              if (emailInput && !emailInput.value) {
                emailInput.value = 'mosposudit3@gmail.com';
                emailInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
              
              var passwordInput = document.querySelector('input[type="password"]');
              if (passwordInput && !passwordInput.value) {
                passwordInput.value = 'Mosposudit123';
                passwordInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
            } catch(e) {}
          }
          
          function acceptCookies() {
            try {
              var cookieButtons = document.querySelectorAll('button');
              for (var i = 0; i < cookieButtons.length; i++) {
                var btn = cookieButtons[i];
                var text = btn.innerText || btn.textContent || '';
                if (text.toLowerCase().includes('accept') || text.toLowerCase().includes('agree')) {
                  if (btn.offsetParent !== null) {
                    btn.click();
                    return true;
                  }
                }
              }
            } catch(e) {}
            return false;
          }
          
          setTimeout(tryAutoFill, 500);
          setTimeout(tryAutoFill, 2000);
          setTimeout(acceptCookies, 1000);
          setTimeout(acceptCookies, 2000);
          
        })();
      ''');
    } catch (e) {
      if (kDebugMode) {
        print('Note: Could not inject helper script: $e');
      }
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

