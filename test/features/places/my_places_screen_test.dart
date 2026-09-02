import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/features/places/presentation/screens/my_places_screen.dart';

import '../../helpers/widget_test_harness.dart';

void main() {
  testWidgets(
      'shows the empty state when no places are added — My Places is '
      'entirely optional', (tester) async {
    await runWithDatabase(
      tester,
      const MaterialApp(home: MyPlacesScreen()),
      (db) async {
        expect(find.textContaining('No places added yet'), findsOneWidget);
        expect(find.text('Add place'), findsOneWidget);
      },
    );
  });
}
