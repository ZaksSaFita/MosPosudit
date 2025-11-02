import 'package:flutter/material.dart';

extension SnackBarHelper on BuildContext {
  void showTopSnackBar({
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final mediaQuery = MediaQuery.of(this);
    final topPadding = mediaQuery.padding.top;
    final topMargin = topPadding + 10;
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            message,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: topMargin,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        elevation: 4,
      ),
    );
  }
}

