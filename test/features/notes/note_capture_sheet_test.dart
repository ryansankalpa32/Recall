import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/features/notes/presentation/widgets/note_capture_sheet.dart';

import '../../helpers/widget_test_harness.dart';

void main() {
  testWidgets('Save stays disabled until text is entered', (tester) async {
    await runWithDatabase(
      tester,
      const MaterialApp(home: Scaffold(body: NoteCaptureSheet())),
      (db) async {
        FilledButton button() =>
            tester.widget<FilledButton>(find.byType(FilledButton));

        expect(button().onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'pick up shoes');
        await tester.pump();

        expect(button().onPressed, isNotNull);
      },
    );
  });

  testWidgets('Save stays disabled for whitespace-only text', (tester) async {
    await runWithDatabase(
      tester,
      const MaterialApp(home: Scaffold(body: NoteCaptureSheet())),
      (db) async {
        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      },
    );
  });
}
