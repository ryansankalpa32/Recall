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
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// Wires up foreground display and tap-to-open for reminder pushes.
  ///
  /// Android doesn't display an FCM notification while the app is in the
  /// foreground, so [onForegroundMessage] shows it locally instead. Taps
  /// (from background or a cold start) route to the note via [onPushTapped].
  Future<void> listenForMessages(PushHandlers handlers) async {
    if (!_isMobile) return;
    _foregroundSub ??= FirebaseMessaging.onMessage.listen((m) =>
        onForegroundMessage(handlers, m.data,
            title: m.notification?.title, body: m.notification?.body));
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp
        .listen((m) => onPushTapped(handlers, m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) await onPushTapped(handlers, initial.data);
  }

  /// Shows a reminder push that arrived while the app was open, under the
  /// note's local id (so it replaces, rather than stacks on, any local
  /// notification for the same note).
  @visibleForTesting
  static Future<void> onForegroundMessage(
    PushHandlers handlers,
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) async {
    if (data['type'] != 'reminder') return;
    final localId = await _localIdFor(handlers, data);
    if (localId == null) return;
    await handlers.show(localId, title ?? 'Recall', body ?? 'You have a reminder');
  }

  /// Opens the note a tapped reminder push refers to.
  @visibleForTesting
  static Future<void> onPushTapped(
    PushHandlers handlers,
    Map<String, dynamic> data,
  ) async {
    if (data['type'] != 'reminder') return;
    final localId = await _localIdFor(handlers, data);
    if (localId != null) handlers.open(localId);
  }

  /// Pushes carry the Firestore id; the app works with local ids.
  static Future<int?> _localIdFor(
    PushHandlers handlers,
    Map<String, dynamic> data,
  ) async {
    final firestoreId = data['noteId'];
    if (firestoreId is! String || firestoreId.isEmpty) return null;
    return handlers.localIdForFirestoreId(firestoreId);
  }

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
    _foregroundSub?.cancel();
    _openedSub?.cancel();
  }
}

/// What [FcmService] needs from the rest of the app to act on a push, kept
/// as plain callbacks so the push logic is testable without Firebase.
class PushHandlers {
  const PushHandlers({
    required this.localIdForFirestoreId,
    required this.show,
    required this.open,
  });

  /// The local note id for a Firestore note id, or null if it isn't synced
  /// to this device (yet).
  final Future<int?> Function(String firestoreId) localIdForFirestoreId;

  /// Shows a notification for the note with this local id.
  final Future<void> Function(int noteId, String title, String body) show;

  /// Opens the note's detail screen.
  final void Function(int noteId) open;
}
