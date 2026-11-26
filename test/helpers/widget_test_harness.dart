import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/providers/core_providers.dart';
import 'package:recall/data/local/database/app_database.dart';

/// Pumps [child] inside a [ProviderScope] backed by a fresh in-memory
/// database, runs [body], then tears the tree down.
///
/// [overrides] are appended after the database override, so a test can swap
/// in a mock parser or scheduler without needing Firebase initialized.
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
  Future<void> Function(AppDatabase db) body, {
  List<Override> overrides = const [],
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
      child: child,
    ),
  );
  // Drift's first stream emission completes on real async, which the
  // fake-async test zone never advances. Without this the screen stays on
  // its CircularProgressIndicator and pumpAndSettle spins until timeout.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();

  await body(db);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  // Advance the fake clock so drift's stream-close timer fires, then close on
  // real async: awaiting db.close() inside the fake-async zone never returns.
  await tester.pump(const Duration(milliseconds: 10));
  await tester.runAsync(() => db.close());
}
