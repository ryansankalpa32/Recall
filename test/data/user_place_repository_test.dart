import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/local/database/app_database.dart';
import 'package:recall/data/repositories/user_place_repository.dart';
import 'package:recall/domain/models/user_place.dart';

void main() {
  late AppDatabase db;
  late UserPlaceRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftUserPlaceRepository(db);
  });

  tearDown(() => db.close());

  UserPlace buildPlace({String label = 'home'}) {
    return UserPlace(
      label: label,
      lat: 51.5,
      lng: -0.1,
      source: UserPlaceSource.manual,
      createdAt: DateTime.now(),
    );
  }

  test('insertPlace then getPlace round-trips the place, manual source by default', () async {
    final id = await repo.insertPlace(buildPlace());
    final fetched = await repo.getPlace(id);

    expect(fetched, isNotNull);
    expect(fetched!.label, 'home');
    expect(fetched.source, UserPlaceSource.manual);
    expect(fetched.lat, 51.5);
  });

  test('watchAllPlaces starts empty — My Places works with zero places added', () async {
    final places = await repo.watchAllPlaces().first;
    expect(places, isEmpty);
  });

  test('deletePlace removes the place', () async {
    final id = await repo.insertPlace(buildPlace());
    await repo.deletePlace(id);

    expect(await repo.getPlace(id), isNull);
  });
}
