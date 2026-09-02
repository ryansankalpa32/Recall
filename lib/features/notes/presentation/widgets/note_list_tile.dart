import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/enums/note_status.dart';
import '../../../../domain/models/note.dart';
import 'status_indicator.dart';
import 'trigger_type_icon.dart';

class NoteListTile extends StatelessWidget {
  const NoteListTile({super.key, required this.note, this.onTap});

  final Note note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheduledDate = note.resolvedDatetime;
    final isDone = note.status == NoteStatus.done;

    return ListTile(
      leading: TriggerTypeIcon(triggerType: note.triggerType),
      title: Text(
        note.taskDescription,
        style: isDone
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: scheduledDate == null
          ? null
          : Text(DateFormat.yMMMd().add_jm().format(scheduledDate)),
      trailing: StatusIndicator(status: note.status),
      onTap: onTap,
    );
  }
}
