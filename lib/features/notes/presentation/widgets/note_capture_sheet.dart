import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/note_form_controller.dart';

/// Free-text capture, opened via [showModalBottomSheet] from
/// [NotesListScreen]'s FAB. Phase 1 has no AI parser, so "manual time
/// reminders" means the user explicitly picks a date/time here — leaving it
/// unset saves a plain, trigger-less note.
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New note', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "e.g. \"pick up dry cleaning\"",
              border: OutlineInputBorder(),
            ),
            onChanged: controller.setRawText,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDateTime(context, ref),
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
                  onPressed: () => controller.setPickedDateTime(null),
                ),
            ],
          ),
          if (formState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Could not save note: ${formState.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: formState.canSave
                ? () async {
                    final saved = await controller.save();
                    if (saved && context.mounted) Navigator.of(context).pop();
                  }
                : null,
            child: formState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
