import 'package:flutter/material.dart';

import '../../features/notes/presentation/screens/note_detail_screen.dart';
import '../../features/places/presentation/screens/my_places_screen.dart';
import '../../features/places/presentation/screens/place_edit_screen.dart';

/// Thin push-helpers over plain [Navigator] — the app stays flat (a list
/// screen, a modal/sheet for capture, pushed routes for detail/places/
/// settings; no bottom-tab navigation), so this exists purely to centralize
/// route construction, not to introduce a router package.
class AppRoutes {
  const AppRoutes._();

  static Future<void> pushNoteDetail(BuildContext context, int noteId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: noteId)),
    );
  }

  static Future<void> pushMyPlaces(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyPlacesScreen()),
    );
  }

  static Future<void> pushAddPlace(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlaceEditScreen()),
    );
  }
}
