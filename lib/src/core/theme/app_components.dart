import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Reusable UI components following the SyncLife design system
class AppComponents {
  /// Primary action button with consistent styling
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppTheme.spacingSm),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }

  /// Secondary action button with outline styling
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppTheme.spacingSm),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }

  /// Text button for tertiary actions
  static Widget textButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppTheme.spacingSm),
          ],
          Text(text),
        ],
      ),
    );
  }

  /// Consistent card container with proper spacing
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double? elevation,
  }) {
    return Card(
      elevation: elevation,
      color: color,
      margin: margin,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
        child: child,
      ),
    );
  }

  /// Loading indicator with consistent styling
  static Widget loadingIndicator({
    String? message,
    double size = 24,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: const CircularProgressIndicator(),
        ),
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.neutralGray600,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  /// Empty state widget with consistent styling
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.neutralGray400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralGray700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralGray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Success message snackbar
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.successColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  /// Error message snackbar
  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  /// Warning message snackbar
  static SnackBar warningSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.warning,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.warningColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  /// Info message snackbar
  static SnackBar infoSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.info,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.infoColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  /// Consistent section header
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacing2xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutralGray600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}