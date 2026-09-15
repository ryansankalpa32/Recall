import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall/data/local/database/app_database.dart';
import 'package:recall/data/repositories/note_repository.dart';
import 'package:recall/domain/models/enums/note_status.dart';
import 'package:recall/domain/models/enums/trigger_type.dart';
import 'package:recall/domain/models/note.dart';
import 'package:recall/features/scheduling/scheduling_service.dart';
import 'package:recall/features/sync/firestore_sync_service.dart';

class MockSchedulingService extends Mock implements SchedulingService {}

const _uid = 'test-uid';

void main() {
  setUpAll(() {
    final now = DateTime.now();
    registerFallbackValue(
      Note(
        rawText: '',
        taskDescription: '',
        triggerType: TriggerType.none,
        status: NoteStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  late AppDatabase db;
  late NoteRepository repo;
  late FakeFirebaseFirestore firestore;
  late MockSchedulingService scheduling;
  late LiveFirestoreSyncService sync;

  /// Same second-precision handling as note_form_controller_test.dart:
  /// drift's dateTime() columns store whole unix seconds, and Firestore's
  /// Timestamp is sub-second-precise, so a DateTime carrying milliseconds
  /// does not survive both round trips identically.
  DateTime secondsFromNow(Duration offset) {
    final t = DateTime.now().add(offset);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  Note buildNote({
    String? firestoreId,
    DateTime? resolvedDatetime,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Note(
      firestoreId: firestoreId,
      rawText: 'call mum',
      taskDescription: 'call mum',
      triggerType: resolvedDatetime == null ? TriggerType.none : TriggerType.time,
      resolvedDatetime: resolvedDatetime,
      status: resolvedDatetime == null ? NoteStatus.pending : NoteStatus.scheduled,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftNoteRepository(db);
    firestore = FakeFirebaseFirestore();
    scheduling = MockSchedulingService();
    when(() => scheduling.scheduleReminder(any())).thenAnswer(
      (_) async => const ReminderOutcome(
        notificationsAllowed: true,
        delivery: ReminderDelivery.exactAlarm,
      ),
    );
    when(() => scheduling.cancelReminder(any())).thenAnswer((_) async {});

    sync = LiveFirestoreSyncService(
      uid: _uid,
      noteRepository: repo,
      schedulingService: scheduling,
      firestore: firestore,
    );
  });

  tearDown(() async {
    await sync.stopListening();
    await db.close();
  });

  CollectionReference<Map<String, dynamic>> notesCollection() =>
      firestore.collection('users').doc(_uid).collection('notes');

  test('reserveDocumentId allocates an id with no write', () async {
    final id = sync.reserveDocumentId();

    expect(id, isNotNull);
    expect(id, isNotEmpty);
    // Allocating the id must not itself create the document.
    expect((await notesCollection().doc(id).get()).exists, isFalse);
  });

  test('pushNote is a no-op when the note has no firestoreId', () async {
    await sync.pushNote(buildNote());

    expect((await notesCollection().get()).docs, isEmpty);
  });

  test('pushNote writes the expected field shapes', () async {
    final when0 = secondsFromNow(const Duration(hours: 2));
    final note = buildNote(firestoreId: 'doc1', resolvedDatetime: when0);

    await sync.pushNote(note);

    final snap = await notesCollection().doc('doc1').get();
    final data = snap.data()!;
    expect(data['rawText'], 'call mum');
    expect(data['triggerType'], 'time', reason: 'enum stored as .name, not the enum object');
    expect(data['status'], 'scheduled');
    expect(data['resolvedDatetime'], isA<Timestamp>());
    expect(data['locationKind'], isNull);
  });

  test('pushDelete removes the document', () async {
    final note = buildNote(firestoreId: 'doc1');
    await sync.pushNote(note);
    expect((await notesCollection().doc('doc1').get()).exists, isTrue);

    await sync.pushDelete(note);

    expect((await notesCollection().doc('doc1').get()).exists, isFalse);
  });

  test(
      'a resolvedDatetime survives push then remote-apply as the same local wall-clock time',
      () async {
    // Exercises the Timestamp <-> local-DateTime round trip end to end: push
    // a note (local -> Timestamp), then feed that exact stored document back
    // through the listener as if it were a remote change (Timestamp ->
    // local), and confirm the two local DateTimes are identical — this is
    // the .toLocal() correctness the plan flagged as needing a real check
    // rather than trusting by inspection.
    final when0 = secondsFromNow(const Duration(hours: 3));
    final pushed = buildNote(firestoreId: 'doc1', resolvedDatetime: when0);
    await sync.pushNote(pushed);

    await sync.startListening();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final local = await repo.getNoteByFirestoreId('doc1');
    expect(local, isNotNull);
    expect(local!.resolvedDatetime, when0);
  });

  test('a new remote note is inserted locally and scheduled', () async {
    final when0 = secondsFromNow(const Duration(hours: 1));
    await notesCollection().doc('remote1').set({
      'rawText': 'water the plants',
      'taskDescription': 'water the plants',
      'triggerType': 'time',
      'locationKind': null,
      'geofenceTransition': null,
      'resolvedDatetime': Timestamp.fromDate(when0),
      'recurrenceRule': null,
      'confidence': 0.8,
      'status': 'scheduled',
      'createdAt': Timestamp.fromDate(when0),
      'updatedAt': Timestamp.fromDate(when0),
    });

    await sync.startListening();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final local = await repo.getNoteByFirestoreId('remote1');
    expect(local, isNotNull);
    expect(local!.taskDescription, 'water the plants');
    verify(() => scheduling.scheduleReminder(any())).called(1);
  });

  test('a remote change older than the local row is ignored (last-write-wins)',
      () async {
    final localUpdatedAt = secondsFromNow(const Duration(minutes: 5));
    final id = await repo.insertNote(
      buildNote(firestoreId: 'doc1', updatedAt: localUpdatedAt)
          .copyWith(taskDescription: 'local version'),
    );

    await notesCollection().doc('doc1').set({
      'rawText': 'call mum',
      'taskDescription': 'stale remote version',
      'triggerType': 'none',
      'locationKind': null,
      'geofenceTransition': null,
      'resolvedDatetime': null,
      'recurrenceRule': null,
      'confidence': null,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(localUpdatedAt),
      // Older than the local row's updatedAt.
      'updatedAt': Timestamp.fromDate(localUpdatedAt.subtract(const Duration(minutes: 1))),
    });

    await sync.startListening();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final local = await repo.getNote(id);
    expect(local!.taskDescription, 'local version',
        reason: 'an older remote write must not overwrite the newer local one');
  });

  test('a remote change newer than the local row is applied', () async {
    final localUpdatedAt = secondsFromNow(const Duration(minutes: 5));
    final id = await repo.insertNote(
      buildNote(firestoreId: 'doc1', updatedAt: localUpdatedAt)
          .copyWith(taskDescription: 'local version'),
    );

    await notesCollection().doc('doc1').set({
      'rawText': 'call mum',
      'taskDescription': 'newer remote version',
      'triggerType': 'none',
      'locationKind': null,
      'geofenceTransition': null,
      'resolvedDatetime': null,
      'recurrenceRule': null,
      'confidence': null,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(localUpdatedAt),
      'updatedAt': Timestamp.fromDate(localUpdatedAt.add(const Duration(minutes: 1))),
    });

    await sync.startListening();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final local = await repo.getNote(id);
    expect(local!.taskDescription, 'newer remote version');
  });

  test('a remote delete cancels the reminder and removes the local row',
      () async {
    final id = await repo.insertNote(buildNote(firestoreId: 'doc1'));
    final now = DateTime.now();
    await notesCollection().doc('doc1').set({
      'rawText': 'call mum',
      'taskDescription': 'call mum',
      'triggerType': 'none',
      'locationKind': null,
      'geofenceTransition': null,
      'resolvedDatetime': null,
      'recurrenceRule': null,
      'confidence': null,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await sync.startListening();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Sanity: the backfill/seed step above must not have deleted it.
    expect(await repo.getNote(id), isNotNull);
    // The initial snapshot's own reconcile pass may itself call
    // cancelReminder (this note has no time either side); isolate the
    // delete-triggered call from that unrelated one.
    clearInteractions(scheduling);

    await notesCollection().doc('doc1').delete();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await repo.getNote(id), isNull);
    verify(() => scheduling.cancelReminder(id)).called(1);
  });

  test('startListening backfills notes with no firestoreId', () async {
    final id = await repo.insertNote(buildNote());
    expect((await repo.getNote(id))!.firestoreId, isNull);

    await sync.startListening();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final backfilled = await repo.getNote(id);
    expect(backfilled!.firestoreId, isNotNull);
    expect((await notesCollection().doc(backfilled.firestoreId).get()).exists, isTrue);
  });
}
