import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/providers/core_providers.dart';
import 'package:recall/data/local/database/app_database.dart';

/// Pumps [child] inside a [ProviderScope] backed by a fresh in-memory
/// database, runs [body], then tears the tree down.
///
/// The explicit unmount at the end matters and is why this helper exists:
/// drift schedules a zero-duration `Timer` when the last query-stream
/// listener cancels (`StreamQueryStore.markAsClosed`). If the
/// [ProviderScope] is left for the framework to dispose after the test body
/// returns, that timer is still pending when `flutter_test` asserts
/// `!timersPending` — and the test fails with "A Timer is still pending even
/// after the widget tree was disposed". `addTearDown` is too late for the
/// same reason: it runs *after* that invariant check.
Future<void> runWithDatabase(
  WidgetTester tester,
  Widget child,
  Future<void> Function(AppDatabase db) body,
) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: child,
    ),
  );
  await tester.pumpAndSettle();

  await body(db);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await db.close();
}
