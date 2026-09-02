import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_place_table.dart';

part 'user_place_dao.g.dart';

@DriftAccessor(tables: [UserPlaceTable])
class UserPlaceDao extends DatabaseAccessor<AppDatabase>
    with _$UserPlaceDaoMixin {
  UserPlaceDao(super.db);

  Stream<List<UserPlaceRow>> watchAllPlaces() {
    return (select(userPlaceTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<UserPlaceRow?> getPlace(int id) {
    return (select(userPlaceTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertPlace(UserPlaceTableCompanion entry) =>
      into(userPlaceTable).insert(entry);

  Future<bool> updatePlace(UserPlaceTableCompanion entry) =>
      update(userPlaceTable).replace(entry);

  Future<int> deletePlace(int id) =>
      (delete(userPlaceTable)..where((t) => t.id.equals(id))).go();
}
