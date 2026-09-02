import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/user_place.dart';

/// State for [PlaceEditScreen]. Per the plan's "place coordinates" decision,
/// [pickedLatLng] is set via the embedded map-picker (drag-a-pin) — no
/// location permission is requested for this, the map just opens at a
/// static default center.
class PlaceFormState {
  const PlaceFormState({
    this.label = 'home',
    this.customName,
    this.pickedLat,
    this.pickedLng,
    this.isSaving = false,
    this.error,
  });

  final String label;
  final String? customName;
  final double? pickedLat;
  final double? pickedLng;
  final bool isSaving;
  final Object? error;

  bool get hasPickedLocation => pickedLat != null && pickedLng != null;
  bool get canSave => hasPickedLocation && !isSaving;

  PlaceFormState copyWith({
    String? label,
    String? customName,
    double? pickedLat,
    double? pickedLng,
    bool? isSaving,
    Object? error,
    bool clearError = false,
  }) {
    return PlaceFormState(
      label: label ?? this.label,
      customName: customName ?? this.customName,
      pickedLat: pickedLat ?? this.pickedLat,
      pickedLng: pickedLng ?? this.pickedLng,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlaceFormController extends Notifier<PlaceFormState> {
  @override
  PlaceFormState build() => const PlaceFormState();

  void setLabel(String label) {
    state = state.copyWith(label: label, clearError: true);
  }

  void setCustomName(String name) {
    state = state.copyWith(customName: name, clearError: true);
  }

  void setPickedLocation(double lat, double lng) {
    state = state.copyWith(pickedLat: lat, pickedLng: lng, clearError: true);
  }

  Future<bool> save() async {
    if (!state.canSave) return false;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final place = UserPlace(
        label: state.label,
        customName: state.customName,
        lat: state.pickedLat!,
        lng: state.pickedLng!,
        source: UserPlaceSource.manual,
        createdAt: DateTime.now(),
      );
      await ref.read(userPlaceRepositoryProvider).insertPlace(place);
      state = const PlaceFormState();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e);
      return false;
    }
  }
}

final placeFormControllerProvider =
    NotifierProvider<PlaceFormController, PlaceFormState>(
        PlaceFormController.new);
