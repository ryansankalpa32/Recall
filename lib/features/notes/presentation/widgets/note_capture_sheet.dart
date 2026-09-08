import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/note_form_controller.dart';
import 'parsed_note_confirmation.dart';

/// Free-text capture, opened via [showModalBottomSheet] from
/// `NotesListScreen`'s FAB.
///
/// Phase 2 flow: type, tap Save, and the sheet swaps to a confirmation card
/// showing what the parser understood (Claude.md: never save an AI-parsed
/// trigger silently). Picking a time by hand skips parsing altogether, and a
/// failed parse falls back to that same manual path so a note can always be
/// saved.
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

  Future<void> _pickDateTime(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      // Today, not yesterday: a reminder can only be set for the future, and
      // the controller rejects a past time anyway.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    ref.read(noteFormControllerProvider.notifier).setPickedDateTime(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
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
            overrideDateTime: formState.pickedDateTime,
            isSaving: formState.stage == CaptureStage.saving,
            notice: formState.notice,
            onConfirm: () => close(controller.confirm()),
            onEditTime: () => _pickDateTime(context, ref),
            onBack: controller.backToEditing,
          ),
        _ => _CaptureForm(
            formState: formState,
            onChanged: controller.setRawText,
            onPickTime: () => _pickDateTime(context, ref),
            onClearTime: () => controller.setPickedDateTime(null),
            onSubmit: () => close(controller.submit()),
          ),
      },
    );
  }
}

class _CaptureForm extends StatelessWidget {
  const _CaptureForm({
    required this.formState,
    required this.onChanged,
    required this.onPickTime,
    required this.onClearTime,
    required this.onSubmit,
  });

  final NoteFormState formState;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;
  final VoidCallback onSubmit;

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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  formState.pickedDateTime == null
                      ? 'Set a reminder time'
                      : DateFormat.yMMMd()
                          .add_jm()
                          .format(formState.pickedDateTime!),
                ),
              ),
            ),
            if (formState.pickedDateTime != null)
              IconButton(
                tooltip: 'Clear time',
                icon: const Icon(Icons.close),
                onPressed: onClearTime,
              ),
          ],
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
                ? "Couldn't read a time from this note. Saving it as written — "
                    'set a time above if you need a reminder.'
                : 'Could not save note: ${formState.error}',
            style: TextStyle(color: theme.colorScheme.error),
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
