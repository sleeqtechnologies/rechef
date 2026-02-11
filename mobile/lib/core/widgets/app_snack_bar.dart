import 'package:flutter/material.dart';

enum SnackBarType { info, success, warning, error }

/// Styled app-wide snack bar with type-based colors and icons.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration? duration,
  }) {
    final (Color bg, Color fg, IconData icon) = switch (type) {
      SnackBarType.info => (const Color(0xFF323232), Colors.white, Icons.info_outline_rounded),
      SnackBarType.success => (const Color(0xFF2E7D32), Colors.white, Icons.check_circle_outline_rounded),
      SnackBarType.warning => (const Color(0xFFF9A825), Colors.black87, Icons.warning_amber_rounded),
      SnackBarType.error => (const Color(0xFFC62828), Colors.white, Icons.error_outline_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
  }
}
