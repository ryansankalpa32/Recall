import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../../domain/models/enums/geofence_transition.dart';
import '../../../domain/models/enums/location_kind.dart';
import '../../../domain/models/enums/note_status.dart';
import '../../../domain/models/enums/trigger_type.dart';
import '../../../domain/models/user_place.dart' show UserPlaceSource;
import 'daos/note_dao.dart';
import 'daos/user_place_dao.dart';
import 'tables/note_table.dart';
import 'tables/user_place_table.dart';

part 'app_database.g.dart';

/// The app's single local database.
///
/// Opened with a *named* on-disk file (`recall.sqlite`, not drift_flutter's
/// unnamed default) because the WorkManager background isolate (see
/// `features/scheduling/workmanager_service.dart`) reopens this same file
/// directly — it has no access to the main isolate's Riverpod container.
@DriftDatabase(tables: [NoteTable, UserPlaceTable], daos: [NoteDao, UserPlaceDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by the background isolate to reopen the exact same database file.
  AppDatabase.forBackgroundIsolate() : super(_openConnection());

  /// Used by tests to inject an in-memory [QueryExecutor]
  /// (`NativeDatabase.memory()`) instead of opening a file on disk.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'recall.sqlite',
    // Required when compiling to the web: drift_flutter throws without it.
    // Both assets are served from `web/` — see that folder's README for
    // where they come from and when to refresh them.
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
