# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is
Recall is a Flutter notes app. Each note works out its own reminder trigger (location, time or both) from free text, using an AI parsing layer. The product spec is in `Readme.md`. `ANALYSIS.md` records how the architecture has changed from that spec, and `implementation_plan.md` covers the Cloud Functions → Express migration. The original design guide, `docs/smart-notes-app-guide.md`, is cited below as "guide §N" but **is not in the repo**. When a guide section matters, use `Readme.md` / `ANALYSIS.md` instead, or ask.

## Hard constraints — do not deviate from these without asking first
- **Geofencing/background location: use `tracelet`.** Not `flutter_background_geolocation`, which is the paid alternative we deliberately moved away from. `tracelet` is not in `pubspec.yaml` yet; it gets added in Phase 3 behind `lib/services/location/geofence_service.dart`.
- **Personal places are manual-first.** A "My places" screen (Home/Work/School/Other, all skippable) must work with zero AI and zero location history before any clustering/learning code exists. Learning is an enhancement layered on top later, never a prerequisite.
- **The AI parser never resolves coordinates.** It only ever outputs a symbolic reference (`location_kind` / `location_value`, e.g. `PERSONAL` / `"home"`). Turning that symbol into a lat/lng is a separate `UserPlace` DB lookup. Keep these two steps in separate code paths.
- **No LLM or Places API key ever ships in the Flutter app.** Every call to either goes through our backend. If you're about to add an API key to a Dart file or `.env` bundled into the app, stop.
- **Show before commit.** Every AI-parsed note shows its interpretation to the user (the confirmation card, `parsed_note_confirmation.dart`) before saving. Never auto-save a parsed trigger silently. When a parse fails, fall back to the manual picker; never save a guess.
- **Background location permission is requested contextually**, the first time a real geofence is needed, never during onboarding. The same applies to notification/exact-alarm permissions (see `SchedulingService`).

## Commands

Flutter app (run from the repo root):
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`: regenerates drift `*.g.dart` files after any change under `lib/data/local/database/` (tables, DAOs, `app_database.dart`)
- `flutter analyze`
- `flutter test` runs all tests; `flutter test test/features/notes/note_form_controller_test.dart` runs one file; add `--plain-name "<test name>"` for a single test
- `flutter run --dart-define=BACKEND_URL=http://<host>:5001`: the default `BACKEND_URL` in `core_providers.dart` / `bootstrap.dart` is a hard-coded LAN IP, so override it for your machine (`10.0.2.2` on an Android emulator)
- `.\run_with_emulator.ps1` sets up `adb reverse` for ports 5001/8080/9099 and runs on a specific physical device against the Firebase emulators

Other dart-defines read by `lib/bootstrap.dart`: `USE_FIREBASE_EMULATOR=true` (routes Functions/Auth/Firestore to the emulators and skips App Check), `FIREBASE_EMULATOR_HOST` (LAN IP for a physical device), `APP_CHECK_DEBUG_TOKEN`.

Backend, `server/` (the one the app actually calls):
- `npm install`, then `npm run dev` (tsc watch + node watch) or `npm run build && npm start`
- Needs `GEMINI_API_KEY` in `server/.env`; exits on startup without it. The Firebase Admin credentials come from `server/serviceAccountKey.json` (gitignored; never commit it or `.env`).
- `npm run get-token` prints an ID token for manual API calls; `Recall_API_Postman_Collection.json` has example requests
- Listens on `PORT` (default 5001). Routes: `POST /parse-note`, `POST /api/notes`, `POST /api/notes/quick-create`, `POST /api/fcm-token` (the `/api/*` routes require a Firebase ID token, see `middleware/auth.ts`)

Firebase emulators / legacy callable (`functions/`):
- `firebase emulators:start` brings up Functions :5001, Firestore :8080, Auth :9099 (see `firebase.json`)
- `cd functions && npm test` runs build + schema-validation tests only (never calls Gemini)

## Architecture

**Layers in `lib/`:** `domain/models` (plain `Note`, `UserPlace`, enums) → `data/local/database` (drift tables + DAOs) → `data/repositories` (`Drift*Repository`) → `features/*/presentation` (Riverpod providers/controllers + screens). Services live in `lib/services/` (AI parser, backend client, FCM, location) and `lib/features/scheduling` + `lib/features/sync`.

**DI / startup:** every provider is declared in `lib/core/providers/core_providers.dart`. `bootstrap.dart` opens the single `AppDatabase`, initializes Firebase (App Check, then emulator routing, then anonymous sign-in), registers FCM, starts Firestore sync, and passes the live instances to `ProviderScope` as overrides. `appDatabaseProvider` throws unless it's overridden. Every init is "degrade, don't crash": if Firebase fails, the app still runs local-only, and `firestoreSyncServiceProvider` stays on `NoopFirestoreSyncService`. Tests rely on these no-op defaults (see `test/helpers/widget_test_harness.dart`).

**Storage:** SQLite (drift) is authoritative. `LiveFirestoreSyncService` mirrors notes to `users/{uid}/notes` both ways, with echo suppression. It is the only file allowed to import `cloud_firestore` types; the rest of the app works with plain `Note`s. In the same way, `HttpRecallApiClient` is the only place HTTP types appear, and it converts every failure into a `NoteParseException`.

**Backend history (read this before touching backend code):** the original plan used the Firebase callable in `functions/`. Cloud Functions + Secret Manager need the paid Blaze plan, so the parser moved to the standalone Express server in `server/`, and the app now uses `HttpRecallApiClient`. `FirebaseRecallApiClient` and `functions/` are legacy. `functions/src/` only has `index.ts` left; `prompt.ts`/`schema.ts` survive only as compiled output under `functions/lib/`. Make parser and prompt changes in `server/src/` (`prompt.ts`, `schema.ts`, `services/aiService.ts`).

**Reminders are delivered server-side:** WorkManager init is commented out in `bootstrap.dart`. `server/src/jobs/reminderScheduler.ts` runs a cron job every minute that runs a `collectionGroup("notes")` query (status `scheduled`, `notificationSent == false`, `resolvedDatetime <= now`; needs a composite Firestore index) and sends an FCM push. So a time reminder only fires if the note has synced to Firestore and the device has registered an FCM token. The client-side `SchedulingService` (local notifications) still exists.

**Parse contract, which is load-bearing:**
- `now` is sent by the client in the request; it is not the server's clock. That keeps the today/tomorrow rule deterministic ("4pm" means today if 4pm hasn't passed, otherwise tomorrow).
- Datetimes are ISO-8601 local wall-clock with **no offset and no `Z`**. `DateTime.parse` only returns a local `DateTime` for that shape, and a stray `Z` shifts every reminder by the device's UTC offset. Both sides reject other shapes. `_localIso` in `http_recall_api_client.dart` is built by hand on purpose, because `intl` would produce non-ASCII digits under some locales.
- The model's JSON schema leaves out `locationKind`, `locationValue` and `recurrenceRule` entirely, so it can't emit Phase 3+ triggers; the server fills them with null. Widen the schema on purpose when that phase begins.
- `@google/genai` must stay at **>= 2.0** (v2 `response_format` / `output_text` API). v1 compiles fine but returns 400 on every request at runtime.

**Dependency pin:** keep `path_provider_android` below 2.3.0 (see the comment in `pubspec.yaml`). Newer versions pull in `jni`, which forces an Android NDK requirement.

## Build order & progress
Do one phase per task, in order. Don't jump ahead to category-based geofencing or learned places before personal-place triggers and time intelligence are working end to end. **Update this section whenever a phase or open item changes status.**

_Last updated: 2026-11-26 (last commit 2026-11-03)_

| # | Phase | Status |
|---|---|---|
| 1 | MVP: notes CRUD, manual time reminders, "My places" screen (no AI, no location tracking) | ✅ Done |
| 2 | Time intelligence: AI parser for free-text time expressions | 🟡 Implemented, still hardening (see open items) |
| 3 | Personal-place location triggers (manually added places only) | ⏭️ Next. `tracelet` not added yet; `GeofenceService` is a stub that throws `UnimplementedError` |
| 4 | Specific-place (one-off) triggers, which adds `/places/nearby` | ⬜ Not started. `placesNearby` throws `UnimplementedError` in both API clients |
| 5 | Personal-place learning (clustering, auto-suggests home/work) | ⬜ Not started |
| 6 | Category-based location triggers (dynamic geofencing) | ⬜ Not started |
| 7 | Confidence & clarification loop | ⬜ Not started |
| 8 | Polish (snooze, inline editing, recurrence/RRULE) | ⬜ Not started |

What Phase 2 has today:
- `POST /parse-note` on `server/` (Gemini via `@google/genai` v2), with the today/tomorrow rule in `server/src/prompt.ts`
- The confirmation card before save, and the manual picker as a fallback when a parse fails
- Drift ↔ Firestore sync under anonymous auth (`LiveFirestoreSyncService`)
- Server-side delivery: the app registers its FCM token via `POST /api/fcm-token` and saves notes via `POST /api/notes`; the cron job in `reminderScheduler.ts` sends the push
- `POST /api/notes/quick-create` (parse + save in one call) exists on the server but the app doesn't call it

Open items before Phase 2 can be called done:
- No `firestore.indexes.json`: the scheduler's `collectionGroup("notes")` query needs a composite index on `(status, notificationSent, resolvedDatetime)` and will fail in production without one
- Offline fallback: with WorkManager disabled, a time reminder can't fire while the device has no network. One idea (from `ANALYSIS.md` §6.3) is to also schedule a local `zonedSchedule` alarm for near-term reminders
- The default `BACKEND_URL` is a hard-coded LAN IP set in two places (`core_providers.dart`, `bootstrap.dart`)
- `server/` has an `npm test` script but no tests
- The legacy `functions/` and `FirebaseRecallApiClient` are still in the tree; decide whether to delete them

## Conventions
- Navigation stays flat: a list screen, a modal/sheet for capture, pushed routes for detail/places/settings. No bottom-tab navigation.
- Every note-list row shows a trigger-type icon (`TriggerTypeIcon`) plus a status indicator (`StatusIndicator`), not raw trigger data.
