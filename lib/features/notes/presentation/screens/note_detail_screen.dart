import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/enums/note_status.dart';
import '../../../../domain/models/enums/trigger_type.dart';
import '../providers/notes_list_provider.dart';
import '../widgets/reminder_time_picker.dart';
import '../widgets/status_indicator.dart';
import '../widgets/trigger_type_icon.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  Future<void> _markDone(WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNote(noteId);
    if (note == null) return;
    final updated = note.copyWith(status: NoteStatus.done, updatedAt: DateTime.now());
    await repo.updateNote(updated);
    await ref.read(schedulingServiceProvider).cancelReminder(noteId);
    unawaited(ref.read(firestoreSyncServiceProvider).pushNote(updated));
  }

  /// Sets or changes the note's reminder time, reschedules the local alarm,
  /// and syncs. Mirrors the capture flow's save-then-schedule handling.
  Future<void> _changeTime(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNote(noteId);
    if (note == null || !context.mounted) return;

    final picked = await pickReminderTime(context, initial: note.resolvedDatetime);
    if (picked == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!picked.isAfter(DateTime.now())) {
      messenger.showSnackBar(const SnackBar(
          content: Text('That time has already passed — pick a later one.')));
      return;
    }

    final scheduling = ref.read(schedulingServiceProvider);
    final sync = ref.read(firestoreSyncServiceProvider);
    var updated = note.copyWith(
      triggerType: TriggerType.time,
      resolvedDatetime: picked,
      status: NoteStatus.scheduled,
      updatedAt: DateTime.now(),
    );
    await repo.updateNote(updated);

    String? caveat;
    try {
      await scheduling.cancelReminder(noteId);
      caveat = (await scheduling.scheduleReminder(updated)).caveat;
    } catch (_) {
      updated = updated.copyWith(status: NoteStatus.pending);
      await repo.updateNote(updated);
      caveat = 'Saved, but the reminder could not be scheduled.';
    }
    unawaited(sync.pushNote(updated));
    if (caveat != null) messenger.showSnackBar(SnackBar(content: Text(caveat)));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    // Fetched before deleting: pushDelete needs the note's firestoreId, which
    // is gone from the local row the instant deleteNote runs.
    final note = await repo.getNote(noteId);
    await ref.read(schedulingServiceProvider).cancelReminder(noteId);
    await repo.deleteNote(noteId);
    if (note != null) {
      unawaited(ref.read(firestoreSyncServiceProvider).pushDelete(note));
    }
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
                if (!isDone) ...[
                  OutlinedButton.icon(
                    onPressed: () => _changeTime(context, ref),
                    icon: const Icon(Icons.edit_calendar),
                    label: Text(note.resolvedDatetime == null
                        ? 'Set reminder time'
                        : 'Change time'),
                  ),
                  const SizedBox(height: 8),
                ],
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
