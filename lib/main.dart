import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'src/app.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Crashlytics only for mobile platforms (not web)
    if (!kIsWeb) {
      FlutterError.onError = (errorDetails) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        } catch (e) {
          debugPrint('Error recording Flutter error to Crashlytics: $e');
        }
      };

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (e) {
          debugPrint('Error recording error to Crashlytics: $e');
        }
        return true;
      };
    }

    // Enable analytics collection (with error handling)
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('Error enabling analytics: $e');
    }

    // Enable performance monitoring (with error handling)
    try {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    } catch (e) {
      debugPrint('Error enabling performance monitoring: $e');
    }

    // Initialize Google Mobile Ads (with error handling and platform check)
    if (!kIsWeb) {
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('Error initializing Google Mobile Ads: $e');
      }
    } else {
      debugPrint('Skipping Google Mobile Ads initialization on web platform');
    }

    runApp(
      const ProviderScope(
        child: SyncLifeApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error in main(): $e');
    debugPrint('Stack trace: $stackTrace');

    // Fallback: run app without Firebase services
    runApp(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Error initializing app. Please try again.'),
            ),
          ),
        ),
      ),
    );
  }
}
