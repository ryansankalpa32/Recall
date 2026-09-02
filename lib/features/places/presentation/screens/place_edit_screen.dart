import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/place_form_controller.dart';

const _defaultLabels = ['home', 'work', 'school', 'other'];

/// Static default center — deliberately not the device's current location.
/// Per the plan's "place coordinates" decision, this screen never requests
/// location permission; the user pans/zooms manually and drops a pin.
const _defaultMapCenter = LatLng(0, 0);

class PlaceEditScreen extends ConsumerStatefulWidget {
  const PlaceEditScreen({super.key});

  @override
  ConsumerState<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends ConsumerState<PlaceEditScreen> {
  Marker? _marker;

  void _onMapTap(LatLng position) {
    ref
        .read(placeFormControllerProvider.notifier)
        .setPickedLocation(position.latitude, position.longitude);
    setState(() {
      _marker = Marker(markerId: const MarkerId('picked'), position: position);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(placeFormControllerProvider);
    final controller = ref.read(placeFormControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add place')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: formState.label,
                  decoration: const InputDecoration(labelText: 'Label'),
                  items: _defaultLabels
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l[0].toUpperCase() + l.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setLabel(value);
                  },
                ),
                if (formState.label == 'other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: controller.setCustomName,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  formState.hasPickedLocation
                      ? 'Pinned at ${formState.pickedLat!.toStringAsFixed(5)}, '
                          '${formState.pickedLng!.toStringAsFixed(5)}'
                      : 'Tap the map to drop a pin for this place.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultMapCenter,
                zoom: 2,
              ),
              onTap: _onMapTap,
              markers: {?_marker},
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: formState.canSave
                  ? () async {
                      final saved = await controller.save();
                      if (saved && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  : null,
              child: formState.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save place'),
            ),
          ),
        ],
      ),
    );
  }
}
