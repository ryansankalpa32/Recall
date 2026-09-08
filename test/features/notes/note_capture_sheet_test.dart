import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall/core/providers/core_providers.dart';
import 'package:recall/features/notes/presentation/widgets/note_capture_sheet.dart';
import 'package:recall/features/notes/presentation/widgets/parsed_note_confirmation.dart';
import 'package:recall/services/ai/note_parser.dart';

import '../../helpers/widget_test_harness.dart';

class MockNoteParser extends Mock implements NoteParser {}

void main() {
  late MockNoteParser parser;

  setUp(() => parser = MockNoteParser());

  Widget sheet() => const MaterialApp(home: Scaffold(body: NoteCaptureSheet()));

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('Save stays disabled until text is entered', (tester) async {
    await runWithDatabase(
      tester,
      sheet(),
      (db) async {
        expect(saveButton(tester).onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'pick up shoes');
        await tester.pump();

        expect(saveButton(tester).onPressed, isNotNull);
      },
      overrides: [noteParserProvider.overrideWithValue(parser)],
    );
  });

  testWidgets('Save stays disabled for whitespace-only text', (tester) async {
    await runWithDatabase(
      tester,
      sheet(),
      (db) async {
        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        expect(saveButton(tester).onPressed, isNull);
      },
      overrides: [noteParserProvider.overrideWithValue(parser)],
    );
  });

  testWidgets('Save swaps the sheet to the confirmation card', (tester) async {
    final when0 = DateTime.now().add(const Duration(hours: 2));
    when(() => parser.parse(any())).thenAnswer(
      (_) async => ParsedNote(
        taskDescription: 'call mum',
        triggerType: 'time',
        resolvedDatetime: when0,
        confidence: 0.93,
      ),
    );

    await runWithDatabase(
      tester,
      sheet(),
      (db) async {
        await tester.enterText(find.byType(TextField), 'call mum at 4pm');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(ParsedNoteConfirmation), findsOneWidget);
        expect(find.text('call mum'), findsOneWidget);
        expect(find.byType(TextField), findsNothing,
            reason: 'the card replaces the form');
        // Displayed, never acted on — branching on it is Phase 7.
        expect(find.textContaining('93% confidence'), findsOneWidget);
      },
      overrides: [noteParserProvider.overrideWithValue(parser)],
    );
  });

  testWidgets('a note with no time reads as a plain note on the card',
      (tester) async {
    when(() => parser.parse(any())).thenAnswer(
      (_) async => const ParsedNote(
        taskDescription: 'buy shoes',
        triggerType: 'none',
        confidence: 0.9,
      ),
    );

    await runWithDatabase(
      tester,
      sheet(),
      (db) async {
        await tester.enterText(find.byType(TextField), 'buy shoes');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.textContaining('No reminder'), findsOneWidget);
      },
      overrides: [noteParserProvider.overrideWithValue(parser)],
    );
  });

  testWidgets('Back returns to the form with the typed text intact',
      (tester) async {
    when(() => parser.parse(any())).thenAnswer(
      (_) async => const ParsedNote(
        taskDescription: 'buy shoes',
        triggerType: 'none',
        confidence: 0.9,
      ),
    );

    await runWithDatabase(
      tester,
      sheet(),
      (db) async {
        await tester.enterText(find.byType(TextField), 'buy shoes');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(ParsedNoteConfirmation), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        expect(saveButton(tester).onPressed, isNotNull,
            reason: 'the text survived, so Save is still enabled');
      },
      overrides: [noteParserProvider.overrideWithValue(parser)],
    );
  });

  testWidgets('a failed parse explains itself and still allows saving',
      (tester) async {
    when(() => parser.parse(any()))
        .thenThrow(const NoteParseException('offline'));

    await runWithDatabase(
      tester,
      sheet(),
      (db) async {
        await tester.enterText(find.byType(TextField), 'call mum at 4pm');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(ParsedNoteConfirmation), findsNothing);
        expect(find.textContaining("Couldn't read a time"), findsOneWidget);
        expect(saveButton(tester).onPressed, isNotNull,
            reason: 'the user must still be able to save without a parse');

        // What the *second* tap does (save directly, without retrying the
        // parser) is asserted in note_form_controller_test.dart. It is not
        // re-asserted here: a successful save pops the sheet, and this harness
        // pumps the sheet as the only route, so the pop leaves the test binding
        // waiting on a transition that never completes.
        // A one-shot query, not `watchAllNotes().first`: drift's query streams
        // do not emit under flutter_test's fake-async binding, so awaiting one
        // inside testWidgets hangs forever.
        expect(await db.select(db.noteTable).get(), isEmpty,
            reason: 'a failed parse must not have written anything');
      },
      overrides: [noteParserProvider.overrideWithValue(parser)],
    );
  });
}
