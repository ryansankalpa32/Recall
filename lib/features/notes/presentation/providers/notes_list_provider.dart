import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/note.dart';

/// Reactive note list — the repository's drift `Stream` query refreshes
/// this automatically on insert/update/delete, no manual invalidation.
final notesListProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).watchAllNotes();
});

final noteByIdProvider = StreamProvider.family<Note?, int>((ref, id) {
  return ref.watch(noteRepositoryProvider).watchNote(id);
});
