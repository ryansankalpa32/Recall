import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/enums/note_status.dart';
import '../providers/notes_list_provider.dart';
import '../widgets/status_indicator.dart';
import '../widgets/trigger_type_icon.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  Future<void> _markDone(WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNote(noteId);
    if (note == null) return;
    await repo.updateNote(
      note.copyWith(status: NoteStatus.done, updatedAt: DateTime.now()),
    );
    await ref.read(schedulingServiceProvider).cancelReminder(noteId);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(schedulingServiceProvider).cancelReminder(noteId);
    await ref.read(noteRepositoryProvider).deleteNote(noteId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: noteAsync.when(
        data: (note) {
          if (note == null) {
            return const Center(child: Text('This note was deleted.'));
          }
          final isDone = note.status == NoteStatus.done;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TriggerTypeIcon(triggerType: note.triggerType),
                    const SizedBox(width: 8),
                    StatusIndicator(status: note.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.taskDescription,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (note.resolvedDatetime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.yMMMd().add_jm().format(note.resolvedDatetime!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const Spacer(),
                if (!isDone)
                  FilledButton.icon(
                    onPressed: () => _markDone(ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark done'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load note: $error')),
      ),
    );
  }
}
