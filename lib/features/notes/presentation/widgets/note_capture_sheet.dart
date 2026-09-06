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

  static Future<void> show(BuildContext context) {
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
      firstDate: now.subtract(const Duration(days: 1)),
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
      if (await saved && context.mounted) Navigator.of(context).pop();
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
        if (formState.error != null) ...[
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
