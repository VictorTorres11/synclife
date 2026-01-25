import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

/// Provider for analytics observer (for navigation tracking)
final analyticsObserverProvider = Provider((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return AnalyticsObserver(analyticsService);
});

/// Navigation observer for automatic screen tracking
class AnalyticsObserver {
  final AnalyticsService _analyticsService;

  AnalyticsObserver(this._analyticsService);

  /// Log screen view when route changes
  void logScreenView(String routeName) {
    _analyticsService.logScreenView(
      routeName,
      routeName.replaceAll('/', '_').replaceAll('-', '_'),
    );
  }
}
