import 'package:flutter/material.dart';
import 'safe_area_wrapper.dart';

/// Wrapper for FloatingActionButton that respects safe areas
/// Ensures FAB doesn't overlap with system navigation buttons
class SafeFABWrapper extends StatelessWidget {
  const SafeFABWrapper({
    super.key,
    required this.child,
    this.location = FloatingActionButtonLocation.endFloat,
  });

  final Widget child;
  final FloatingActionButtonLocation location;

  @override
  Widget build(BuildContext context) {
    // Get the bottom safe area to adjust FAB position
    final bottomSafeArea = context.bottomSafeArea;

    // If there's no system navigation, use default positioning
    if (bottomSafeArea == 0) {
      return child;
    }

    // Wrap FAB with padding to avoid system navigation
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomSafeArea > 0 ? 8.0 : 0.0, // Small additional padding
      ),
      child: child,
    );
  }
}

/// Extension for Scaffold to easily add safe FAB
extension SafeScaffoldExtension on Scaffold {
  Scaffold withSafeFAB(Widget? fab) {
    if (fab == null) return this;

    return Scaffold(
      key: key,
      appBar: appBar,
      body: body,
      floatingActionButton: SafeFABWrapper(child: fab),
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}
