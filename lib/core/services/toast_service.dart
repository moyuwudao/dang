import 'package:flutter/material.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class ToastService {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final icon = _getIcon(type);
    final backgroundColor = _getBackgroundColor(type, theme);
    final textColor = _getTextColor(type, theme);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        duration: duration,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  static IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_outline;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  static Color _getBackgroundColor(ToastType type, ThemeData theme) {
    switch (type) {
      case ToastType.success:
        return theme.colorScheme.primaryContainer;
      case ToastType.error:
        return theme.colorScheme.errorContainer;
      case ToastType.warning:
        return theme.colorScheme.warningContainer;
      case ToastType.info:
        return theme.colorScheme.secondaryContainer;
    }
  }

  static Color _getTextColor(ToastType type, ThemeData theme) {
    switch (type) {
      case ToastType.success:
        return theme.colorScheme.onPrimaryContainer;
      case ToastType.error:
        return theme.colorScheme.onErrorContainer;
      case ToastType.warning:
        return theme.colorScheme.onWarningContainer;
      case ToastType.info:
        return theme.colorScheme.onSecondaryContainer;
    }
  }
}