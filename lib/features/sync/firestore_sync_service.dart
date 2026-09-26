import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/note_repository.dart';
import '../../domain/models/enums/geofence_transition.dart';
import '../../domain/models/enums/location_kind.dart';
import '../../domain/models/enums/note_status.dart';
import '../../domain/models/enums/trigger_type.dart';
import '../../domain/models/note.dart';
import '../scheduling/scheduling_service.dart';

/// Syncs notes to Firestore, alongside — never instead of — the local
/// SQLite database that stays authoritative for on-device scheduling.
///
/// This is the only place `cloud_firestore` types are allowed to appear,
/// mirroring the rule `firebase_recall_api_client.dart` already applies to
/// `cloud_functions`: everything outside this file works with plain [Note]s,
/// so the rest of the app never needs to know Firestore exists.
abstract class FirestoreSyncService {
  /// Allocates a Firestore document id with no network round-trip, or null
  /// if sync isn't available (Firebase/Auth failed at bootstrap).
  String? reserveDocumentId();

  /// One-shot write of the complete note. Never throws — failures are
  /// logged, not propagated, because SQLite is authoritative and a push
  /// failure must never affect the caller's save flow.
  Future<void> pushNote(Note note);

  /// Deletes the note's Firestore doc, if it has one. Same never-throws
  /// contract as [pushNote].
  Future<void> pushDelete(Note note);

  /// Backfills any local note missing a [Note.firestoreId], then starts the
  /// live snapshot listener. Idempotent.
  Future<void> startListening();

  Future<void> stopListening();
}

/// The default — every existing test and any dev machine without Firebase
/// configured gets this, so nothing outside `bootstrap.dart` needs to know
/// whether sync actually came up.
class NoopFirestoreSyncService implements FirestoreSyncService {
  const NoopFirestoreSyncService();

  @override
  String? reserveDocumentId() => null;

  @override
  Future<void> pushNote(Note note) async {}

  @override
  Future<void> pushDelete(Note note) async {}

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}
}

class LiveFirestoreSyncService implements FirestoreSyncService {
  LiveFirestoreSyncService({
    required this._uid,
    required this._noteRepository,
    required this._schedulingService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final NoteRepository _noteRepository;
  final SchedulingService _schedulingService;
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection('users').doc(_uid).collection('notes');

  @override
  String? reserveDocumentId() => _notes.doc().id;

  @override
  Future<void> pushNote(Note note) async {
    final firestoreId = note.firestoreId;
    if (firestoreId == null) return;
    try {
      await _notes.doc(firestoreId).set(_toFirestore(note), SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('FirestoreSyncService: push failed for note ${note.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> pushDelete(Note note) async {
    final firestoreId = note.firestoreId;
    if (firestoreId == null) return;
    try {
      await _notes.doc(firestoreId).delete();
    } catch (error, stackTrace) {
      debugPrint(
          'FirestoreSyncService: delete push failed for note ${note.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> startListening() async {
    await _backfillMissingFirestoreIds();
    _subscription ??= _notes.snapshots().listen(
          _handleSnapshot,
          onError: (Object error) {
            debugPrint('FirestoreSyncService: listener error: $error');
          },
        );
  }

  @override
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Notes created before this column existed, or while sync was down at
  /// insert time, have a null [Note.firestoreId]. One mechanism (this)
  /// covers both cases: on every `startListening()`, find them, allocate a
  /// doc id, persist it locally, and push.
  Future<void> _backfillMissingFirestoreIds() async {
    final notes = await _noteRepository.watchAllNotes().first;
    for (final note in notes.where((n) => n.firestoreId == null)) {
      final withId = note.copyWith(firestoreId: reserveDocumentId());
      await _noteRepository.updateNote(withId);
      await pushNote(withId);
    }
  }

  Future<void> _handleSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    for (final change in snapshot.docChanges) {
      // Suppress the echo of our own pending local write — a snapshot
      // listener fires immediately with a pending write, before the server
      // ack. Without this, every push this device makes would loop straight
      // back through here as if it were a remote change.
      if (change.doc.metadata.hasPendingWrites) continue;

      final local = await _noteRepository.getNoteByFirestoreId(change.doc.id);

      if (change.type == DocumentChangeType.removed) {
        if (local?.id != null) {
          await _schedulingService.cancelReminder(local!.id!);
          await _noteRepository.deleteNote(local.id!);
        }
        continue;
      }

      final data = change.doc.data();
      if (data == null) continue;
      final remote = _fromFirestore(change.doc.id, data);

      if (local == null) {
        final id = await _noteRepository.insertNote(remote);
        await _reschedule(remote.copyWith(id: id));
        continue;
      }

      // Last-write-wins: only apply a remote change strictly newer than
      // what's already local, so this device's own more-recent edit (made
      // while offline, say) isn't clobbered by a stale remote snapshot.
      if (!remote.updatedAt.isAfter(local.updatedAt)) continue;

      final merged = remote.copyWith(id: local.id);
      await _noteRepository.updateNote(merged);
      await _reschedule(merged);
    }
  }

  Future<void> _reschedule(Note note) async {
    final hasFutureTime = note.status == NoteStatus.scheduled &&
        note.resolvedDatetime != null &&
        note.resolvedDatetime!.isAfter(DateTime.now());
    if (hasFutureTime) {
      try {
        await _schedulingService.scheduleReminder(note);
      } catch (_) {
        // Best-effort — the note is still correct locally either way.
      }
    } else if (note.id != null) {
      await _schedulingService.cancelReminder(note.id!);
    }
  }

  Map<String, dynamic> _toFirestore(Note note) => {
        'rawText': note.rawText,
        'taskDescription': note.taskDescription,
        'triggerType': note.triggerType.name,
        'locationKind': note.locationKind?.name,
        'geofenceTransition': note.geofenceTransition?.name,
        'resolvedDatetime': note.resolvedDatetime == null
            ? null
            : Timestamp.fromDate(note.resolvedDatetime!),
        'recurrenceRule': note.recurrenceRule,
        'confidence': note.confidence,
        'status': note.status.name,
        'notificationSent': false,
        'createdAt': Timestamp.fromDate(note.createdAt),
        'updatedAt': Timestamp.fromDate(note.updatedAt),
      };

  Note _fromFirestore(String docId, Map<String, dynamic> data) {
    final locationKind = data['locationKind'] as String?;
    final geofenceTransition = data['geofenceTransition'] as String?;
    return Note(
      firestoreId: docId,
      rawText: data['rawText'] as String,
      taskDescription: data['taskDescription'] as String,
      triggerType: TriggerType.fromName(data['triggerType'] as String),
      locationKind:
          locationKind == null ? null : LocationKind.fromName(locationKind),
      geofenceTransition: geofenceTransition == null
          ? null
          : GeofenceTransition.fromName(geofenceTransition),
      // `_localIso`'s doc comment (firebase_recall_api_client.dart) explains
      // why `resolvedDatetime` is treated as an implicitly-local wall-clock
      // value everywhere else in this app. `Timestamp.toDate()` returns a
      // UTC-flagged DateTime representing the same instant; `.toLocal()`
      // converts it to the device's local wall-clock so a synced reminder
      // schedules at the same hour it was written at, not shifted by
      // whatever the writing device's UTC offset happened to be.
      resolvedDatetime:
          (data['resolvedDatetime'] as Timestamp?)?.toDate().toLocal(),
      recurrenceRule: data['recurrenceRule'] as String?,
      confidence: (data['confidence'] as num?)?.toDouble(),
      status: NoteStatus.fromName(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate().toLocal(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate().toLocal(),
    );
  }
}
