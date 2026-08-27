# Recall — project context for Claude Code

## What this is
A Flutter notes app where each note resolves its own reminder trigger (location, time, or both) from free text via an AI parsing layer. The full spec lives in `README.md` (root) and `docs/smart-notes-app-guide.md` — read the relevant section before implementing anything non-trivial, especially location (guide §4) and AI parsing (guide §3).

## Hard constraints — do not deviate from these without asking first
- **Geofencing/background location: use `tracelet`.** Not `flutter_background_geolocation` — that's the paid alternative we deliberately moved away from. See guide §4.2 and the known-challenges note on plugin maturity.
- **Personal places are manual-first.** A "My places" screen (Home/Work/School/Other, all skippable) must work with zero AI and zero location history before any clustering/learning code exists. Learning is an enhancement layered on top later, never a prerequisite. See guide §4.1.
- **The AI parser never resolves coordinates.** It only ever outputs a symbolic reference (`location_kind` / `location_value`, e.g. `PERSONAL` / `"home"`). Turning that symbol into a lat/lng is a separate `UserPlace` DB lookup. Keep these two steps in separate code paths — see guide §3 vs §4.
- **No LLM or Places API key ever ships in the Flutter app.** Every call to either goes through our backend proxy. If you're about to add an API key to a Dart file or `.env` bundled into the app, stop.
- **Show before commit.** Every AI-parsed note displays its interpretation back to the user (the confirmation card) before saving — never auto-save a parsed trigger silently. See guide §12.
- **Background location permission is requested contextually**, the first time a real geofence is needed — never during onboarding. See guide §4.1 and §9.

## Tech stack
- UI: Flutter (Dart), Riverpod for state management
- Local storage: `drift` (preferred) or `sqflite`
- Scheduling: `workmanager` (deferred tasks) + `flutter_local_notifications` (exact-alarm triggers)
- Location/geofencing: `tracelet`
- Permissions: `permission_handler`
- Backend: thin proxy holding the LLM + Places API keys — see the backend section of the guide for the two endpoints (`/parse-note`, `/places/nearby`)

## Build order
Follow the phases in guide §8, in order, one phase per session/task:
1. MVP — notes CRUD, manual time reminders, "My places" screen (no AI, no location tracking)
2. Time intelligence — AI parser for free-text time expressions
3. Personal-place location triggers (manually added places only)
4. Specific-place (one-off) triggers
5. Personal-place learning (clustering, auto-suggests home/work)
6. Category-based location triggers (dynamic geofencing)
7. Confidence & clarification loop
8. Polish

Don't jump ahead to category-based geofencing or learned places before personal-place triggers and time intelligence are working end to end.

## Commands
- `flutter pub get` — install dependencies
- `flutter run` — run on a connected device or emulator
- `flutter test` — run tests
- `flutter analyze` — lint
- `flutter build apk --release` — release build

## Conventions
- Navigation stays flat: a list screen, a modal/sheet for capture, pushed routes for detail/places/settings. No bottom-tab navigation.
- Every note-list row shows an icon for trigger type plus a status indicator, not raw trigger data — see guide §12 for the visual pattern.