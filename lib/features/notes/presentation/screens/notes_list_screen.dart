import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../providers/notes_list_provider.dart';
import '../widgets/note_capture_sheet.dart';
import '../widgets/note_list_tile.dart';

/// Initial route. Flat navigation — no bottom tabs: capture is a modal
/// sheet, "My places" and note detail are pushed routes.
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall'),
        actions: [
          IconButton(
            tooltip: 'My places',
            icon: const Icon(Icons.place_outlined),
            onPressed: () => AppRoutes.pushMyPlaces(context),
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No notes yet. Tap + to write one — try something like '
                  '"pick up shoes" or "call mum at 6pm".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteListTile(
                note: note,
                onTap: () => AppRoutes.pushNoteDetail(context, note.id!),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load notes: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NoteCaptureSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
