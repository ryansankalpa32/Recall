import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/user_place.dart';

final userPlacesProvider = StreamProvider<List<UserPlace>>((ref) {
  return ref.watch(userPlaceRepositoryProvider).watchAllPlaces();
});
