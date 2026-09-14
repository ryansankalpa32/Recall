import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/note_form_controller.dart';
import 'parsed_note_confirmation.dart';

/// Free-text capture, opened via [showModalBottomSheet] from
/// `NotesListScreen`'s FAB.
///
/// Phase 2 flow: type, tap Save, and the sheet swaps to a confirmation card
/// showing what the parser understood (Claude.md: never save an AI-parsed
/// trigger silently). There is no manual time entry anywhere in this flow —
/// a reminder time only ever comes from the AI parse. A failed parse falls
/// back to saving the note as plain text with no reminder, so a note can
/// always be saved regardless of whether the parser is reachable.
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
          ),
        _ => _CaptureForm(
            formState: formState,
            onChanged: controller.setRawText,
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
    required this.onSubmit,
  });

  final NoteFormState formState;
  final ValueChanged<String> onChanged;
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
                ? "Couldn't read a time from this note. Tap Save again to "
                    'save as a plain note.'
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
