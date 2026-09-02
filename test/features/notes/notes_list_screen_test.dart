import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/features/notes/presentation/screens/notes_list_screen.dart';

import '../../helpers/widget_test_harness.dart';

void main() {
  testWidgets('shows the empty state when there are no notes', (tester) async {
    await runWithDatabase(
      tester,
      const MaterialApp(home: NotesListScreen()),
      (db) async {
        expect(find.textContaining('No notes yet'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );
  });

  testWidgets('tapping the FAB opens the note capture sheet', (tester) async {
    await runWithDatabase(
      tester,
      const MaterialApp(home: NotesListScreen()),
      (db) async {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.text('New note'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      },
    );
  });
}
