import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showTopRightSnackbar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.hideCurrentSnackBar();
    
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final snackbarWidth = 260.0;
    final rightMargin = 16.0;
    final topMargin = 16.0;
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: SizedBox(
          width: snackbarWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor ?? Colors.blue.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: topMargin,
          right: rightMargin,
          bottom: screenHeight - 80,
          left: screenWidth - snackbarWidth - rightMargin,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 2,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopRightSnackbar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    showTopRightSnackbar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopRightSnackbar(
      context,
      message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopRightSnackbar(
      context,
      message,
      backgroundColor: Colors.orange.shade600,
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }
}

