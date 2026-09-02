import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications`.
///
/// Notification-action buttons (done/snooze) are deliberately not part of
/// this Phase 1 surface — per the plan, they're Phase 8 "Polish", per
/// Claude.md's build order. Phase 1 notifications are tap-to-open only.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'note_reminders';
  static const _channelName = 'Note reminders';
  static const _channelDescription = 'Reminders for notes with a scheduled time';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? iosGranted ?? false);
  }

  /// Android 12+ exact-alarm allowance — a separate setting from the
  /// notification permission above, requested through this plugin (not
  /// `permission_handler`) per the plan's "permission split" design.
  Future<bool> requestExactAlarmsPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    return granted ?? true; // non-Android platforms: nothing to request
  }

  Future<bool> canScheduleExactAlarms() async {
    final can = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications();
    return can ?? true;
  }

  /// Schedules a local notification for [scheduledDate]. Falls back to
  /// [AndroidScheduleMode.inexactAllowWhileIdle] when exact-alarm isn't
  /// granted, per the plan's Play Store policy note — the caller is
  /// responsible for surfacing "may fire a few minutes late" to the user in
  /// that case.
  Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool useExactAlarm,
  }) async {
    await _plugin.zonedSchedule(
      id: noteId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: useExactAlarm
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'note:$noteId',
    );
  }

  Future<void> showImmediate({
    required int noteId,
    required String title,
    required String body,
  }) {
    return _plugin.show(
      id: noteId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'note:$noteId',
    );
  }

  Future<void> cancel(int noteId) => _plugin.cancel(id: noteId);
}
