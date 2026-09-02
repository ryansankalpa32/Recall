import 'package:flutter/material.dart';

import '../../../../domain/models/enums/note_status.dart';

/// Trailing status chip for a [NoteListTile].
///
/// [NoteStatus.needsClarification] has a color defined even though it's
/// unreachable until Phase 7 — keeps the switch exhaustive without a
/// `default` case masking a forgotten status.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.status});

  final NoteStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      NoteStatus.pending => (Colors.grey, 'Pending'),
      NoteStatus.scheduled => (Colors.blue, 'Scheduled'),
      NoteStatus.notified => (Colors.amber.shade700, 'Notified'),
      NoteStatus.done => (Colors.green, 'Done'),
      NoteStatus.needsClarification => (Colors.deepOrange, 'Needs review'),
    };
    return Tooltip(
      message: label,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
