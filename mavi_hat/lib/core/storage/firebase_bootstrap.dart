import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Safe bootstrapper for Firebase Core, FirebaseAuth, Cloud Firestore,
/// Firebase Analytics, and Firebase Crashlytics.
///
/// When `google-services.json` / `GoogleService-Info.plist` is present in the
/// build, [isAvailable] becomes `true`, Crashlytics error handlers are
/// attached, and repositories mirror writes to Firestore. When running locally
/// without platform Firebase credentials (or in automated tests), it safely
/// falls back to Hive CE local storage.
abstract final class FirebaseBootstrap {
  static bool _isAvailable = false;

  static bool get isAvailable => _isAvailable;

  static Future<bool> tryInitialize() async {
    try {
      await Firebase.initializeApp();
      _isAvailable = true;

      // Wire Flutter & Platform uncaught errors into Firebase Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      return true;
    } catch (_) {
      _isAvailable = false;
      return false;
    }
  }

  static FirebaseAuth? get authOrNull =>
      _isAvailable ? FirebaseAuth.instance : null;

  static FirebaseFirestore? get firestoreOrNull =>
      _isAvailable ? FirebaseFirestore.instance : null;

  static FirebaseAnalytics? get analyticsOrNull =>
      _isAvailable ? FirebaseAnalytics.instance : null;

  static FirebaseCrashlytics? get crashlyticsOrNull =>
      _isAvailable ? FirebaseCrashlytics.instance : null;

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_isAvailable) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (_) {
      // Ignore telemetry failures in offline/local mode
    }
  }
}
