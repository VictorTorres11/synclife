import 'package:flutter/material.dart';

/// Custom SafeArea wrapper that provides consistent safe area handling
/// across the app, especially for Android devices with system navigation buttons
class SafeAreaWrapper extends StatelessWidget {
  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }
}

/// Extension to get safe area insets for custom positioning
extension SafeAreaExtension on BuildContext {
  EdgeInsets get safeAreaInsets => MediaQuery.of(this).viewInsets;
  EdgeInsets get systemPadding => MediaQuery.of(this).padding;

  /// Get the bottom safe area height (useful for positioning elements above system navigation)
  double get bottomSafeArea => MediaQuery.of(this).padding.bottom;

  /// Get the top safe area height (useful for status bar)
  double get topSafeArea => MediaQuery.of(this).padding.top;

  /// Check if device has system navigation buttons (gesture navigation vs button navigation)
  bool get hasSystemNavigationButtons => MediaQuery.of(this).padding.bottom > 0;
}
