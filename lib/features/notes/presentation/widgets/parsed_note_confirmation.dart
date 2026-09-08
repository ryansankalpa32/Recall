import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/enums/trigger_type.dart';
import '../../../../services/ai/note_parser.dart';
import 'trigger_type_icon.dart';

/// The "show before commit" step: what the parser understood, shown back to the
/// user before anything is written.
///
/// Required by Claude.md — an AI-parsed trigger is never saved silently. The
/// confidence is displayed but never acted on; branching on it is the Phase 7
/// clarification loop, not this.
class ParsedNoteConfirmation extends StatelessWidget {
  const ParsedNoteConfirmation({
    super.key,
    required this.parsed,
    required this.overrideDateTime,
    required this.isSaving,
    this.notice,
    required this.onConfirm,
    required this.onEditTime,
    required this.onBack,
  });

  final ParsedNote parsed;

  /// A time the user picked by hand on this card, which wins over the parsed
  /// one.
  final DateTime? overrideDateTime;

  final bool isSaving;

  /// A message that must be resolved before this card can commit — currently
  /// only "the parsed time has just passed", which `confirm()` raises when the
  /// card has been sitting open long enough for its own answer to expire.
  final String? notice;

  final VoidCallback onConfirm;
  final VoidCallback onEditTime;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveDateTime = overrideDateTime ?? parsed.resolvedDatetime;
    final hasTime = effectiveDateTime != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Is this right?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.taskDescription,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TriggerTypeIcon(
                      triggerType:
                          hasTime ? TriggerType.time : TriggerType.none,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasTime
                            ? DateFormat.yMMMEd()
                                .add_jm()
                                .format(effectiveDateTime)
                            : 'No reminder — saved as a plain note',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                if (overrideDateTime == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Interpreted with '
                    '${(parsed.confidence * 100).round()}% confidence',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 12),
          Text(
            notice!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isSaving ? null : onConfirm,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onEditTime,
                icon: const Icon(Icons.schedule),
                label: Text(hasTime ? 'Change time' : 'Set a time'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: isSaving ? null : onBack,
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
