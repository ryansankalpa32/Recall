import '../../data/repositories/note_repository.dart';
import '../../domain/models/enums/note_status.dart';
import '../sync/firestore_sync_service.dart';

/// Marks scheduled notes whose time has passed as `notified`.
///
/// The phone's local alarm delivers every time reminder, but an alarm can't
/// run app code when it fires, so nothing else updates the note's status.
/// This runs on app start and whenever the app returns to the foreground,
/// and syncs each change.
///
/// It deliberately doesn't cancel the alarm: by now it has fired, and
/// cancelling would also clear the shown notification from the tray.
class PastDueMarker {
  const PastDueMarker({
    required this.noteRepository,
    required this.syncService,
  });

  final NoteRepository noteRepository;
  final FirestoreSyncService syncService;

  /// Returns how many notes were marked.
  Future<int> markPastDue({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final due = await noteRepository.getPastDueScheduled(at);
    for (final note in due) {
      final updated = note.copyWith(status: NoteStatus.notified, updatedAt: at);
      await noteRepository.updateNote(updated);
      await syncService.pushNote(updated);
    }
    return due.length;
  }
}
