import 'package:flutter/material.dart';

import '../../../../domain/models/enums/trigger_type.dart';

/// Leading icon for a [NoteListTile], switched on [TriggerType].
///
/// The switch is exhaustive: [TriggerType.location]/[TriggerType.both]
/// branches exist even though Phase 1 UI never constructs those values
/// (unreachable until Phase 3) — see the plan's Phase 1 note-list-row
/// section.
class TriggerTypeIcon extends StatelessWidget {
  const TriggerTypeIcon({super.key, required this.triggerType});

  final TriggerType triggerType;

  @override
  Widget build(BuildContext context) {
    final (icon, tooltip) = switch (triggerType) {
      TriggerType.time => (Icons.schedule, 'Time reminder'),
      TriggerType.location => (Icons.place_outlined, 'Location reminder'),
      TriggerType.both => (Icons.explore_outlined, 'Time + location reminder'),
      TriggerType.none => (Icons.notes_outlined, 'Note'),
    };
    return Icon(icon, semanticLabel: tooltip);
  }
}
