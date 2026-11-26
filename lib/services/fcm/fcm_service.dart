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

/// Manages Firebase Cloud Messaging tokens.
///
/// This class never *asks* for notification permission. Per Claude.md,
/// permissions are requested in context: `SchedulingService` asks the first
/// time the user saves a time reminder, and the capture flow then calls
/// [ensureRegistered]. Until permission exists, no token is registered.
class FcmService {
  FcmService(this._apiClient);

  final RecallApiClient _apiClient;
  bool _initialized = false;
  bool _registered = false;
  StreamSubscription<String>? _tokenRefreshSub;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Startup: installs the background handler and registers the token only
  /// if permission was already granted on an earlier run. Never prompts.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await ensureRegistered();
  }

  /// Registers this device's token with the backend if notification
  /// permission is granted. Safe to call repeatedly; does nothing once
  /// registered, or when permission is missing. Never prompts.
  Future<void> ensureRegistered() async {
    if (_registered || !_isMobile) return;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        debugPrint('Recall: FCM not registered yet (permission: $status)');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      _tokenRefreshSub ??=
          FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
      // Only latch on success, so a backend outage is retried next call.
      _registered = await _registerToken(token);
    } catch (e, st) {
      debugPrint('Recall: FCM registration failed: $e\n$st');
    }
  }

  Future<bool> _registerToken(String token) async {
    // Never log the full token: it is a push credential for this device.
    debugPrint('Recall: Registering FCM token: '
        '${token.length > 10 ? token.substring(0, 10) : token}...');
    try {
      await _apiClient.registerFcmToken(token);
      return true;
    } catch (e) {
      debugPrint('Recall: Failed to register FCM token with backend: $e');
      return false;
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
