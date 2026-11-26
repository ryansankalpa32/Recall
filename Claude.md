# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is
Recall is a Flutter notes app. Each note works out its own reminder trigger (location, time or both) from free text, using an AI parsing layer. The product spec is in `Readme.md`. `ANALYSIS.md` records how the architecture has changed from that spec, and `implementation_plan.md` covers the Cloud Functions → Express migration. The original design guide, `docs/smart-notes-app-guide.md`, is cited below as "guide §N" but **is not in the repo**. When a guide section matters, use `Readme.md` / `ANALYSIS.md` instead, or ask.

## Hard constraints — do not deviate from these without asking first
- **Geofencing/background location: use `tracelet`.** Not `flutter_background_geolocation`, which is the paid alternative we deliberately moved away from. `tracelet` is not in `pubspec.yaml` yet; it gets added in Phase 3 behind `lib/services/location/geofence_service.dart`.
- **Personal places are manual-first.** A "My places" screen (Home/Work/School/Other, all skippable) must work with zero AI and zero location history before any clustering/learning code exists. Learning is an enhancement layered on top later, never a prerequisite.
- **The AI parser never resolves coordinates.** It only ever outputs a symbolic reference (`location_kind` / `location_value`, e.g. `PERSONAL` / `"home"`). Turning that symbol into a lat/lng is a separate `UserPlace` DB lookup. Keep these two steps in separate code paths.
- **No LLM or Places API key ever ships in the Flutter app.** Every call to either goes through our backend. If you're about to add an API key to a Dart file or `.env` bundled into the app, stop.
- **Show before commit.** Every AI-parsed note shows its interpretation to the user (the confirmation card, `parsed_note_confirmation.dart`) before saving. Never auto-save a parsed trigger silently. A user-edited time ("Edit time") is also shown on the card before saving. When a parse fails, offer the manual date/time picker (`reminder_time_picker.dart`) or a plain note; never save a guess.
- **Background location permission is requested contextually**, the first time a real geofence is needed, never during onboarding. The same applies to notification/exact-alarm permissions: `SchedulingService` asks on the first time-reminder save, and `FcmService` never prompts (it only registers once permission exists).

## Commands

Flutter app (run from the repo root):
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`: regenerates drift `*.g.dart` files after any change under `lib/data/local/database/` (tables, DAOs, `app_database.dart`)
- `flutter analyze`
- `flutter test` runs all tests; `flutter test test/features/notes/note_form_controller_test.dart` runs one file; add `--plain-name "<test name>"` for a single test
- `flutter run --dart-define=BACKEND_URL=http://<host>:5001`: `BACKEND_URL` is read only in `lib/core/config.dart`; without it the app falls back to a dev LAN IP and logs a warning (`10.0.2.2` on an Android emulator)
- If a widget test that uses `runWithDatabase` hangs, the cause is usually drift under the fake-async clock; see the comments in `test/helpers/widget_test_harness.dart`
- `.\run_with_emulator.ps1` sets up `adb reverse` for ports 5001/8080/9099 and runs on a specific physical device against the Firebase emulators

Other dart-defines read by `lib/bootstrap.dart`: `USE_FIREBASE_EMULATOR=true` (routes Functions/Auth/Firestore to the emulators and skips App Check), `FIREBASE_EMULATOR_HOST` (LAN IP for a physical device), `APP_CHECK_DEBUG_TOKEN`.

Backend, `server/` (the one the app actually calls):
- `npm install`, then `npm run dev` (tsc watch + node watch) or `npm run build && npm start`
- Needs `GEMINI_API_KEY` in `server/.env`; exits on startup without it. The Firebase Admin credentials come from `server/serviceAccountKey.json` (gitignored; never commit it or `.env`).
- `npm run get-token` prints an ID token for manual API calls; `Recall_API_Postman_Collection.json` has example requests
- `npm test` builds and runs `server/test/*.test.ts` with `node --test` (no Firebase or Gemini calls). Keep testable logic out of files that import `config/firebase`, which loads credentials (e.g. `src/localTime.ts`, `middleware/rateLimit.ts`).
- Listens on `PORT` (default 5001). Routes: `POST /parse-note`, `POST /api/notes`, `POST /api/notes/quick-create`, `POST /api/fcm-token`. **All require a Firebase ID token** (`middleware/auth.ts`). The two Gemini routes share a 20/min per-uid limit (`middleware/geminiRateLimit.ts`).
- `firebase deploy --only firestore:indexes` deploys `firestore.indexes.json`, which the reminder cron job's query needs

Firebase emulators / legacy callable (`functions/`):
- `firebase emulators:start` brings up Functions :5001, Firestore :8080, Auth :9099 (see `firebase.json`)
- `cd functions && npm test` runs build + schema-validation tests only (never calls Gemini)

## Architecture

**Layers in `lib/`:** `domain/models` (plain `Note`, `UserPlace`, enums) → `data/local/database` (drift tables + DAOs) → `data/repositories` (`Drift*Repository`) → `features/*/presentation` (Riverpod providers/controllers + screens). Services live in `lib/services/` (AI parser, backend client, FCM, location) and `lib/features/scheduling` + `lib/features/sync`.

**DI / startup:** every provider is declared in `lib/core/providers/core_providers.dart`. `bootstrap.dart` opens the single `AppDatabase`, initializes Firebase (App Check, then emulator routing, then anonymous sign-in), registers FCM, starts Firestore sync, and passes the live instances to `ProviderScope` as overrides. `appDatabaseProvider` throws unless it's overridden. Every init is "degrade, don't crash": if Firebase fails, the app still runs local-only, and `firestoreSyncServiceProvider` stays on `NoopFirestoreSyncService`. Tests rely on these no-op defaults (see `test/helpers/widget_test_harness.dart`).

**Storage:** SQLite (drift) is authoritative. `LiveFirestoreSyncService` mirrors notes to `users/{uid}/notes` both ways, with echo suppression. It is the only file allowed to import `cloud_firestore` types; the rest of the app works with plain `Note`s. In the same way, `HttpRecallApiClient` is the only place HTTP types appear, and it converts every failure into a `NoteParseException`.

**Backend history (read this before touching backend code):** the original plan used the Firebase callable in `functions/`. Cloud Functions + Secret Manager need the paid Blaze plan, so the parser moved to the standalone Express server in `server/`, and the app now uses `HttpRecallApiClient`. `FirebaseRecallApiClient` and `functions/` are legacy. `functions/src/` only has `index.ts` left; `prompt.ts`/`schema.ts` survive only as compiled output under `functions/lib/`. Make parser and prompt changes in `server/src/` (`prompt.ts`, `schema.ts`, `services/aiService.ts`).

**Reminder delivery is "alarm first, push as backup":**
- `SchedulingService` schedules every time reminder as a local `zonedSchedule` alarm: exact if it's 6 hours or less away and allowed, inexact otherwise. WorkManager isn't used for delivery any more; its init stays commented out, and `cancelReminder` only clears legacy tasks.
- `LiveFirestoreSyncService` writes `localAlarm: true` on scheduled time notes. `server/src/jobs/reminderScheduler.ts` runs every minute, queries `collectionGroup("notes")` (status `scheduled`, `notificationSent == false`, `resolvedDatetime <= now`; index in `firestore.indexes.json`), and for `localAlarm` notes only marks them `notified`. It sends an FCM push only for notes without a local alarm, e.g. ones created through `/api/notes/quick-create`.
- Keep these invariants or reminders duplicate or vanish:
  - If scheduling fails, the note must be downgraded to `pending` **in Firestore too** (see `NoteFormController._persist`).
  - Sync must not call `cancelReminder` on a remote `notified` update; that would clear the notification already shown.
- Taps on local notifications (`note:<id>` payload) and on pushes (Firestore id → local id) open `NoteDetailScreen` through `AppRoutes.navigatorKey`. `FcmService` shows pushes itself while the app is in the foreground.
- `localAlarm` notes skip the server's recurrence handling. Revisit that when Phase 8 adds RRULEs.

**Parse contract, which is load-bearing:**
- `now` is sent by the client in the request; it is not the server's clock. That keeps the today/tomorrow rule deterministic ("4pm" means today if 4pm hasn't passed, otherwise tomorrow).
- Datetimes are ISO-8601 local wall-clock with **no offset and no `Z`**. `DateTime.parse` only returns a local `DateTime` for that shape, and a stray `Z` shifts every reminder by the device's UTC offset. Both sides reject other shapes. `_localIso` in `http_recall_api_client.dart` is built by hand on purpose, because `intl` would produce non-ASCII digits under some locales.
- The model's JSON schema leaves out `locationKind`, `locationValue` and `recurrenceRule` entirely, so it can't emit Phase 3+ triggers; the server fills them with null. Widen the schema on purpose when that phase begins.
- `@google/genai` must stay at **>= 2.0** (v2 `response_format` / `output_text` API). v1 compiles fine but returns 400 on every request at runtime.

**Dependency pin:** keep `path_provider_android` below 2.3.0 (see the comment in `pubspec.yaml`). Newer versions pull in `jni`, which forces an Android NDK requirement.

## Build order & progress
Do one phase per task, in order. Don't jump ahead to category-based geofencing or learned places before personal-place triggers and time intelligence are working end to end. **Update this section whenever a phase or open item changes status.**

_Last updated: 2026-11-26 (branch `phase-2-hardening`)_

| # | Phase | Status |
|---|---|---|
| 1 | MVP: notes CRUD, manual time reminders, "My places" screen (no AI, no location tracking) | ✅ Done |
| 2 | Time intelligence: AI parser for free-text time expressions | ✅ Code complete; device end-to-end check pending (see below) |
| 3 | Personal-place location triggers (manually added places only) | ⏭️ Next. `tracelet` not added yet; `GeofenceService` is a stub that throws `UnimplementedError` |
| 4 | Specific-place (one-off) triggers, which adds `/places/nearby` | ⬜ Not started. `placesNearby` throws `UnimplementedError` in both API clients |
| 5 | Personal-place learning (clustering, auto-suggests home/work) | ⬜ Not started |
| 6 | Category-based location triggers (dynamic geofencing) | ⬜ Not started |
| 7 | Confidence & clarification loop | ⬜ Not started |
| 8 | Polish (snooze, inline editing, recurrence/RRULE) | ⬜ Not started |

What Phase 2 has:
- `POST /parse-note` on `server/` (Gemini via `@google/genai` v2, auth + rate limit), with the today/tomorrow rule in `server/src/prompt.ts`
- The confirmation card with "Edit time", and the manual date/time picker when a parse fails; "Set / Change time" on the note detail screen
- Drift ↔ Firestore sync under anonymous auth (`LiveFirestoreSyncService`), which is the only path notes take to the server (the app no longer calls `POST /api/notes`)
- Local alarms with FCM as backup (see Architecture), foreground push display, and tap-to-open
- Contextual notification permission; IANA time-zone conversion on the server (`src/localTime.ts`)
- Tests: Flutter (`flutter test`) and server (`npm test` in `server/`)

Still to do for Phase 2:
- Run the end-to-end check on a device: "call mum in 3 minutes" → one notification with the app open, in the background and killed; tap opens the note; Firestore ends `status: notified`; a failed parse plus a manual time still fires; no permission prompt at launch
- Deploy the index: `firebase deploy --only firestore:indexes`
- `POST /api/notes/quick-create` exists on the server but the app doesn't call it
- Decide whether to delete the legacy `functions/` and `FirebaseRecallApiClient`

## Conventions
- Navigation stays flat: a list screen, a modal/sheet for capture, pushed routes for detail/places/settings. No bottom-tab navigation.
- Every note-list row shows a trigger-type icon (`TriggerTypeIcon`) plus a status indicator (`StatusIndicator`), not raw trigger data.
