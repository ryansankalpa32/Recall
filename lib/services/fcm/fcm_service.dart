import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../backend/recall_api_client.dart';

/// Top-level background message handler for FCM.
/// Must be outside of any class.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Recall: Handling a background message: ${message.messageId}');
  // The notification will be shown automatically by the OS because the payload
  // includes the 'notification' block. We don't need to do anything here for now.
}

/// Manages Firebase Cloud Messaging tokens and permissions.
class FcmService {
  FcmService(this._apiClient);

  final RecallApiClient _apiClient;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> init() async {
    if (_initialized) return;

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Only request permission and fetch token on mobile devices
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission();
        debugPrint('Recall: FCM permission status: ${settings.authorizationStatus}');
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          // Get the token and register it
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await _registerToken(token);
          }

          // Listen for token refreshes
          _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
            _registerToken(token);
          });
        }
      } catch (e, st) {
        debugPrint('Recall: Failed to initialize FCM: $e\n$st');
      }
    }

    _initialized = true;
  }

  Future<void> _registerToken(String token) async {
    debugPrint('Recall: Registering FCM token: ${token.substring(0, 10)}...');
    try {
      await _apiClient.registerFcmToken(token);
    } catch (e) {
      debugPrint('Recall: Failed to register FCM token with backend: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
