import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/note_form_controller.dart';
import 'parsed_note_confirmation.dart';
import 'reminder_time_picker.dart';

/// Free-text capture, opened via [showModalBottomSheet] from
/// `NotesListScreen`'s FAB.
///
/// Phase 2 flow: type, tap Save, and the sheet swaps to a confirmation card
/// showing what the parser understood (Claude.md: never save an AI-parsed
/// trigger silently); the card's "Edit time" lets the user correct it. A
/// failed parse falls back to an optional hand-picked time, or a plain note,
/// so a note can always be saved whether or not the parser is reachable.
class NoteCaptureSheet extends ConsumerWidget {
  const NoteCaptureSheet({super.key});

  /// Opens the sheet on a clean form.
  ///
  /// The reset is why this takes a [WidgetRef]: the controller is not
  /// auto-disposed, so without it a sheet dismissed mid-flow leaks its text and
  /// its `parseFailed` flag into the next note.
  static Future<void> show(BuildContext context, WidgetRef ref) {
    ref.read(noteFormControllerProvider.notifier).reset();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NoteCaptureSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(noteFormControllerProvider);
    final controller = ref.read(noteFormControllerProvider.notifier);

    Future<void> close(Future<bool> saved) async {
      if (!await saved || !context.mounted) return;
      // Read before popping: the notice lives in the controller's post-save
      // state, and it is the only place the user is told that a reminder will
      // not fire the way they asked.
      final notice = ref.read(noteFormControllerProvider).notice;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      if (notice != null) {
        messenger?.showSnackBar(SnackBar(content: Text(notice)));
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: switch (formState.stage) {
        CaptureStage.confirming || CaptureStage.saving
            when formState.parsed != null =>
          ParsedNoteConfirmation(
            parsed: formState.parsed!,
            isSaving: formState.stage == CaptureStage.saving,
            notice: formState.notice,
            onConfirm: () => close(controller.confirm()),
            onBack: controller.backToEditing,
            onEditTime: () async {
              final picked = await pickReminderTime(context,
                  initial: formState.parsed!.resolvedDatetime);
              if (picked != null) controller.overrideParsedTime(picked);
            },
          ),
        _ => _CaptureForm(
            formState: formState,
            onChanged: controller.setRawText,
            onSubmit: () => close(controller.submit()),
            onPickTime: () async {
              final picked = await pickReminderTime(context,
                  initial: formState.manualTime);
              if (picked != null) controller.setManualTime(picked);
            },
            onClearTime: () => controller.setManualTime(null),
          ),
      },
    );
  }
}

class _CaptureForm extends StatelessWidget {
  const _CaptureForm({
    required this.formState,
    required this.onChanged,
    required this.onSubmit,
    required this.onPickTime,
    required this.onClearTime,
  });

  final NoteFormState formState;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New note', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'e.g. "call mum at 4pm"',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        if (formState.notice != null) ...[
          const SizedBox(height: 8),
          Text(
            formState.notice!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ] else if (formState.error != null) ...[
          const SizedBox(height: 8),
          Text(
            formState.parseFailed
                ? "Couldn't read a time from this note. Pick one below, or "
                    'tap Save to save it as a plain note.'
                : 'Could not save note: ${formState.error}',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        if (formState.parseFailed) ...[
          const SizedBox(height: 12),
          if (formState.manualTime == null)
            OutlinedButton.icon(
              onPressed: formState.isBusy ? null : onPickTime,
              icon: const Icon(Icons.alarm_add),
              label: const Text('Add reminder time'),
            )
          else
            Row(
              children: [
                const Icon(Icons.alarm),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft),
                    onPressed: formState.isBusy ? null : onPickTime,
                    child: Text(DateFormat.yMMMEd()
                        .add_jm()
                        .format(formState.manualTime!)),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove reminder time',
                  onPressed: formState.isBusy ? null : onClearTime,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: formState.canSubmit ? onSubmit : null,
          child: formState.isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
