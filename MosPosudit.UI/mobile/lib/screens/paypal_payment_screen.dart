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

  /// Initializes PayPal payment flow by creating order and loading WebView
  Future<void> _initializePayPal() async {
    try {
      final paypalOrder = await _paymentService.createPayPalOrder(widget.orderData);

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
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
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
                // Inject JavaScript to ensure keyboard appears on input focus
                _enableKeyboardSupport();
              }
            },
            onWebResourceError: (WebResourceError error) {
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

      // Configure Android WebView for keyboard input and proper functionality
      if (_controller!.platform is AndroidWebViewController) {
        final androidController = _controller!.platform as AndroidWebViewController;
        AndroidWebViewController.enableDebugging(kDebugMode);
        androidController.setMediaPlaybackRequiresUserGesture(false);
        androidController.setOnShowFileSelector((params) async => []);
        
        // Note: Permission requests for camera/microphone are handled automatically
        // by Android based on permissions declared in AndroidManifest.xml
        // The permissions (CAMERA, RECORD_AUDIO, MODIFY_AUDIO_SETTINGS) are already
        // declared in AndroidManifest.xml, so Android will prompt the user if needed
      }
      
      _controller!.enableZoom(true);
      _controller!.setBackgroundColor(Colors.white);
      await _controller!.loadRequest(Uri.parse(_approvalUrl!));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
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
        try {
          await _cartService.clearCart();
        } catch (e) {
          // Silently fail - cart will be cleared by backend
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

  /// Enables keyboard support and auto-fills email by injecting JavaScript
  Future<void> _enableKeyboardSupport() async {
    if (_controller == null) return;
    
    const email = 'mosposudit3@gmail.com';
    
    try {
      await _controller!.runJavaScript('''
        (function() {
          var emailToFill = '${email}';
          
          // Function to auto-fill email field
          function autoFillEmail() {
            // Try multiple selectors for email fields
            var emailSelectors = [
              'input[type="email"]',
              'input[name*="email" i]',
              'input[id*="email" i]',
              'input[placeholder*="email" i]',
              'input[name*="mail" i]',
              'input[id*="mail" i]'
            ];
            
            for (var i = 0; i < emailSelectors.length; i++) {
              var emailInputs = document.querySelectorAll(emailSelectors[i]);
              emailInputs.forEach(function(input) {
                if (input.value === '' || input.value === null) {
                  input.value = emailToFill;
                  
                  // Trigger input events so PayPal detects the value
                  var events = ['input', 'change', 'keyup', 'blur'];
                  events.forEach(function(eventType) {
                    var event = new Event(eventType, { bubbles: true });
                    input.dispatchEvent(event);
                  });
                }
              });
            }
          }
          
          // Function to ensure keyboard appears on input focus
          function ensureKeyboardShows(input) {
            if (!input.hasAttribute('data-keyboard-handler')) {
              input.setAttribute('data-keyboard-handler', 'true');
              
              // Remove readonly and disabled attributes that might block input
              input.removeAttribute('readonly');
              input.removeAttribute('disabled');
              
              // Ensure input is focusable
              if (input.tabIndex < 0) {
                input.tabIndex = 0;
              }
              
              input.addEventListener('click', function(e) {
                e.stopPropagation();
                setTimeout(function() {
                  input.focus();
                  input.click();
                }, 10);
              }, true);
              
              input.addEventListener('touchstart', function(e) {
                e.stopPropagation();
                setTimeout(function() {
                  input.focus();
                }, 10);
              }, true);
              
              input.addEventListener('focus', function() {
                // Ensure keyboard shows by forcing focus
                setTimeout(function() {
                  input.click();
                  input.focus();
                }, 100);
              });
            }
          }
          
          // Handle existing inputs
          function setupExistingInputs() {
            // Auto-fill email first
            autoFillEmail();
            
            // Setup keyboard handlers for all inputs
            var inputs = document.querySelectorAll('input, textarea, [contenteditable="true"]');
            inputs.forEach(ensureKeyboardShows);
          }
          
          // Setup inputs when DOM is ready
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', setupExistingInputs);
          } else {
            setupExistingInputs();
          }
          
          // Also handle dynamically added inputs (PayPal often loads forms dynamically)
          var observer = new MutationObserver(function(mutations) {
            // Auto-fill email on new elements
            autoFillEmail();
            
            // Setup keyboard handlers for new inputs
            var inputs = document.querySelectorAll('input, textarea, [contenteditable="true"]');
            inputs.forEach(ensureKeyboardShows);
          });
          
          if (document.body) {
            observer.observe(document.body, {
              childList: true,
              subtree: true
            });
          }
          
          // Re-run auto-fill every second for the first 10 seconds (in case form loads slowly)
          var attempts = 0;
          var fillInterval = setInterval(function() {
            autoFillEmail();
            attempts++;
            if (attempts >= 10) {
              clearInterval(fillInterval);
            }
          }, 1000);
        })();
      ''');
    } catch (e) {
      // Silently fail - keyboard should still work with default behavior
      if (kDebugMode) {
        print('Failed to inject keyboard support JavaScript: $e');
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

