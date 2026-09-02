import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../providers/user_places_provider.dart';

/// Per Claude.md's hard constraint: works with zero AI and zero location
/// history. All entries — including the default Home/Work/School/Other
/// labels — are added manually and are entirely skippable; nothing here
/// blocks the rest of the app if left empty.
class MyPlacesScreen extends ConsumerWidget {
  const MyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(userPlacesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My places')),
      body: placesAsync.when(
        data: (places) {
          if (places.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No places added yet. This is entirely optional — add '
                  'Home, Work, or any other place you want reminders to '
                  'recognize later.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(place.customName ?? place.label),
                subtitle: Text(
                  '${place.lat.toStringAsFixed(5)}, ${place.lng.toStringAsFixed(5)}',
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load places: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRoutes.pushAddPlace(context),
        icon: const Icon(Icons.add),
        label: const Text('Add place'),
      ),
    );
  }
}
