import 'package:flutter/material.dart';

extension SnackBarHelper on BuildContext {
  void showTopSnackBar({
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final mediaQuery = MediaQuery.of(this);
    final topPadding = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: backgroundColor ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          16,
          topPadding + 70,
          16,
          screenHeight - topPadding - 150,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        elevation: 6,
      ),
    );
  }
}

void showGlobalSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
  final mediaQuery = MediaQuery.of(context);
  final topPadding = mediaQuery.padding.top;
  final screenHeight = mediaQuery.size.height;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
      backgroundColor: backgroundColor ?? Colors.black87,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        16,
        topPadding + 70,
        16,
        screenHeight - topPadding - 150,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      duration: const Duration(seconds: 3),
      elevation: 6,
    ),
  );
}

