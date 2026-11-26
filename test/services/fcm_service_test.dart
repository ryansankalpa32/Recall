import 'package:flutter_test/flutter_test.dart';
import 'package:recall/features/scheduling/notification_service.dart';
import 'package:recall/services/fcm/fcm_service.dart';

void main() {
  late List<String> shown;
  late List<int> opened;
  late PushHandlers handlers;

  setUp(() {
    shown = [];
    opened = [];
    handlers = PushHandlers(
      localIdForFirestoreId: (id) async => id == 'fs1' ? 7 : null,
      show: (noteId, title, body) async => shown.add('$noteId|$title|$body'),
      open: opened.add,
    );
  });

  group('foreground pushes', () {
    test('are shown under the note\'s local id', () async {
      await FcmService.onForegroundMessage(
        handlers,
        {'type': 'reminder', 'noteId': 'fs1'},
        title: 'Reminder',
        body: 'call mum',
      );
      expect(shown, ['7|Reminder|call mum']);
    });

    test('are ignored for notes not synced to this device', () async {
      await FcmService.onForegroundMessage(
          handlers, {'type': 'reminder', 'noteId': 'unknown'});
      expect(shown, isEmpty);
    });

    test('ignore messages that are not reminders', () async {
      await FcmService.onForegroundMessage(handlers, {'noteId': 'fs1'});
      expect(shown, isEmpty);
    });
  });

  group('tapped pushes', () {
    test('open the note by local id', () async {
      await FcmService.onPushTapped(
          handlers, {'type': 'reminder', 'noteId': 'fs1'});
      expect(opened, [7]);
    });

    test('do nothing without a noteId', () async {
      await FcmService.onPushTapped(handlers, {'type': 'reminder'});
      expect(opened, isEmpty);
    });
  });

  test('local notification payloads map back to note ids', () {
    expect(NotificationService.noteIdFromPayload('note:42'), 42);
    expect(NotificationService.noteIdFromPayload('other'), isNull);
    expect(NotificationService.noteIdFromPayload(null), isNull);
  });
}
