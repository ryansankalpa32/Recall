# Recall — Comprehensive Project & Architecture Analysis

> **Analysis Document:** Evaluation of `Claude.md`, system specifications, and the active codebase state.  
> **Repository:** Recall (Flutter + Node.js / Express + Firebase / Firestore + Google Gemini)  
> **Current Git Branch:** `phase-2-time-intelligence`  
> **Date:** October 2026  

---

## 1. Executive Summary

**Recall** is an intelligent context-aware notes and reminders application built with Flutter. Unlike standard task and reminder apps (Google Keep, Apple Reminders, Todoist) which require manual date/time picking or manual address pinning, Recall parses natural language free-text notes into executable triggers:
1. **Time Triggers:** Dynamic wall-clock disambiguation (e.g. "at 4pm", "tomorrow morning", "in 20 minutes").
2. **Personal Location Triggers:** Learned or manual personal anchors (e.g. "home", "work", "school").
3. **Category Location Triggers:** Dynamic geofences matching generic categories (e.g. "buy shoes" triggers at any shoe store).

The document [`Claude.md`](file:///d:/Context%20aware/Recall/Claude.md) defines the core vision, hard architectural boundaries, technology stack, and an 8-phase sequential build order. 

This analysis evaluates `Claude.md` against the active codebase, documents critical architectural evolutions that have occurred during development (such as the pivot to server-side FCM scheduling), audits adherence to hard constraints, and provides an actionable path forward.

---

## 2. Hard Constraints Audit & Compliance

`Claude.md` outlines six non-negotiable architectural rules. The table below audits the codebase against each constraint:

| # | Hard Constraint (`Claude.md`) | Intended Rationale | Current Codebase Status | Compliance |
|---|---|---|---|---|
| **1** | **Geofencing: Use `tracelet`, not `flutter_background_geolocation`** | Avoid paid commercial SDK dependencies and leverage free open-source geofencing. | `tracelet` is scheduled for **Phase 3** (Personal-place triggers). Currently, neither is added to [`pubspec.yaml`](file:///d:/Context%20aware/Recall/pubspec.yaml). | 🟢 **Compliant** (Ready for Phase 3 integration) |
| **2** | **Personal places are manual-first** | User must be able to define Home/Work/School manually with zero AI or location history. Learning is an enhancement, not a prerequisite. | Implemented via [`MyPlacesScreen`](file:///d:/Context%20aware/Recall/lib/features/places/presentation/screens/my_places_screen.dart), [`PlaceEditScreen`](file:///d:/Context%20aware/Recall/lib/features/places/presentation/screens/place_edit_screen.dart), and local Drift database storage. | 🟢 **Fully Compliant** |
| **3** | **AI parser never resolves coordinates** | The AI parser only outputs symbolic keys (`PERSONAL` / `"home"`). Lat/Lng conversion is strictly handled by local `UserPlace` DB lookup. | In [`server/src/schema.ts`](file:///d:/Context%20aware/Recall/server/src/schema.ts), location fields are restricted; the backend model only handles task description and local wall-clock time. No coordinates are touched by LLM. | 🟢 **Fully Compliant** |
| **4** | **No LLM or Places API key in Flutter app** | Protect private API keys from client-side extraction; enforce server proxying. | Verified. `GEMINI_API_KEY` is loaded strictly via `process.env` in [`server/src/index.ts`](file:///d:/Context%20aware/Recall/server/src/index.ts). No API keys are embedded in Dart files or Flutter assets. | 🟢 **Fully Compliant** |
| **5** | **Show before commit** | Every AI-parsed note must display its interpretation (confirmation card) to the user before saving. Never auto-save silently. | Implemented via [`ParsedNoteConfirmation`](file:///d:/Context%20aware/Recall/lib/features/notes/presentation/widgets/parsed_note_confirmation.dart) inside [`NoteCaptureSheet`](file:///d:/Context%20aware/Recall/lib/features/notes/presentation/widgets/note_capture_sheet.dart). | 🟢 **Fully Compliant** |
| **6** | **Contextual background location permissions** | Request background location permissions only when a real geofence is created, never at onboarding or app startup. | Verified. [`lib/bootstrap.dart`](file:///d:/Context%20aware/Recall/lib/bootstrap.dart) does not request location permissions on launch. Permissions are deferred to [`PermissionService`](file:///d:/Context%20aware/Recall/lib/features/scheduling/permission_service.dart). | 🟢 **Fully Compliant** |

---

## 3. Architectural Evolution & System Architecture

### 3.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            FLUTTER CLIENT                                   │
│                                                                             │
│   [Free-Text Input] ──► [ParsedNoteConfirmation (Show-Before-Commit)]       │
│                                      │                                      │
│                                      ▼                                      │
│                   ┌──────────────────────────────────────┐                  │
│                   │         Drift SQLite Database        │                  │
│                   │      (Offline-First Local Storage)   │                  │
│                   └──────────────────┬───────────────────┘                  │
│                                      │                                      │
│                                      ▼                                      │
│                   ┌──────────────────────────────────────┐                  │
│                   │       LiveFirestoreSyncService       │                  │
│                   │   (Two-Way Realtime Cloud Sync)      │                  │
│                   └──────────────────┬───────────────────┘                  │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │ HTTPS / Firestore Listener
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       STANDALONE BACKEND (Express + Node 22)                │
│                                                                             │
│   ┌───────────────────────────┐         ┌───────────────────────────────┐   │
│   │   POST /parse-note        │         │   POST /api/fcm-token         │   │
│   │   - Google GenAI SDK v2   │         │   - Stores device FCM tokens  │   │
│   │   - Structured JSON output│         │   - users/{uid}/fcmTokens     │   │
│   │   - Gemini 3.5 Flash Lite │         └───────────────────────────────┘   │
│   └─────────────┬─────────────┘                         │                   │
│                 │                                       │                   │
│                 ▼                                       ▼                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      Reminder Scheduler (Cron Job)                  │   │
│   │  - Runs every 60s: queries collectionGroup("notes")                 │   │
│   │  - Detects due tasks where resolvedDatetime <= now                  │   │
│   │  - Dispatches high-priority Firebase Cloud Messages (FCM)           │   │
│   │  - Calculates next occurrence for recurring RRULE tasks             │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │ FCM Push Protocol
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DEVICE NOTIFICATION TRAY                           │
│   - High Priority Notification: "Reminder: <taskDescription>"              │
│   - Channel: note_reminders                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Key Architectural Pivots from Original Specification

During the execution of Phase 1 and Phase 2, three major architectural shifts occurred:

#### 1. Transition from Firebase Cloud Functions to Standalone Express Server
* **Original Plan:** Deploy `parseNote` as a Firebase Cloud Function using Firebase Secret Manager for the Gemini API key.
* **The Reality:** Google Cloud Functions and Secret Manager require the paid Firebase **Blaze plan**.
* **The Solution:** Implemented [`server/`](file:///d:/Context%20aware/Recall/server) as a standalone Node.js / Express microservice. It uses `dotenv` for `GEMINI_API_KEY`, Firebase Admin SDK with Service Account credentials, and is readily deployable to free container hosts (Render, Railway, Fly.io) or locally.

#### 2. Transition from Client-Side Scheduling to Server-Side Cron + FCM
* **Original Spec (`Claude.md` § Tech Stack):** 
  `workmanager` (deferred background tasks) + `flutter_local_notifications` (exact alarms).
* **The Reality:** Android 12+ battery optimizations, OEM-specific task killers, and Doze mode aggressively terminate background isolates and delay `WorkManager` execution, making time-sensitive note reminders unreliable.
* **The Solution:** 
  1. Built a background cron scheduler in [`server/src/jobs/reminderScheduler.ts`](file:///d:/Context%20aware/Recall/server/src/jobs/reminderScheduler.ts) that executes every minute.
  2. Integrated Firebase Cloud Messaging (FCM). The Flutter client registers tokens via [`POST /api/fcm-token`](file:///d:/Context%20aware/Recall/server/src/routes/fcmRoutes.ts).
  3. When `resolvedDatetime <= now`, the server sends a high-priority FCM message, ensuring prompt delivery regardless of whether the Flutter app is in foreground, background, or killed.
  4. WorkManager initialization in [`lib/bootstrap.dart`](file:///d:/Context%20aware/Recall/lib/bootstrap.dart) was quietly commented out in favor of [`FcmService`](file:///d:/Context%20aware/Recall/lib/services/fcm/fcm_service.dart).

#### 3. Dual Storage & Synchronization Layer (Drift + Firestore)
* Notes and Places are stored locally using **Drift** (SQLite) for instantaneous offline read/write and zero UI latency.
* **[`LiveFirestoreSyncService`](file:///d:/Context%20aware/Recall/lib/features/sync/firestore_sync_service.dart)** listens to Firestore collection `users/{uid}/notes` and performs bidirectional updates with echo suppression (ignoring writes matching pending local state).

---

## 4. Codebase Components Breakdown

### 4.1 Flutter Application (`lib/`)

- **State Management & DI:** `flutter_riverpod` (v3.4.2) with `riverpod_annotation`. Global singletons (Database, NotificationService, SyncService) are initialized in [`lib/bootstrap.dart`](file:///d:/Context%20aware/Recall/lib/bootstrap.dart) and overridden in `ProviderScope`.
- **Local Persistence:** Drift SQLite tables:
  - `notes_table.dart`: Tracks `id`, `firestoreId`, `rawText`, `taskDescription`, `triggerType`, `locationKind`, `locationValue`, `resolvedDatetime`, `confidence`, `status`, `notificationSent`.
  - `user_places_table.dart`: Stores `label`, `lat`, `lng`, `radiusM`, `source` (`MANUAL` or `LEARNED`).
- **Presentation Layer (Flat Navigation):**
  - [`NotesListScreen`](file:///d:/Context%20aware/Recall/lib/features/notes/presentation/screens/notes_list_screen.dart): Flat list showing note cards with visual icons ([`TriggerTypeIcon`](file:///d:/Context%20aware/Recall/lib/features/notes/presentation/widgets/trigger_type_icon.dart)) and status badges ([`StatusIndicator`](file:///d:/Context%20aware/Recall/lib/features/notes/presentation/widgets/status_indicator.dart)).
  - [`NoteCaptureSheet`](file:///d:/Context%20aware/Recall/lib/features/notes/presentation/widgets/note_capture_sheet.dart): Modal bottom sheet for free-text input and confirmation review.
  - [`MyPlacesScreen`](file:///d:/Context%20aware/Recall/lib/features/places/presentation/screens/my_places_screen.dart): Manual place management with Google Maps picker support.
- **Backend API Integration:**
  - [`HttpRecallApiClient`](file:///d:/Context%20aware/Recall/lib/services/backend/http_recall_api_client.dart): Replaced the Firebase callable client with HTTP `POST` requests to `$BACKEND_URL/parse-note`. Formats local wall-clock time in ISO-8601 without UTC offsets (`YYYY-MM-DDTHH:mm:ss`).

### 4.2 Standalone Node.js Backend (`server/`)

- **Runtime & Framework:** Node.js 22, Express 4, TypeScript 5.
- **AI Engine:** `@google/genai` (v2 SDK) invoking `gemini-3.5-flash-lite`.
- **Prompt Engineering ([`server/src/prompt.ts`](file:///d:/Context%20aware/Recall/server/src/prompt.ts)):**
  - Enforces strict wall-clock resolution: time-only input evaluates to today if the time is in the future, or tomorrow if it has already passed.
  - Vague times map to canonical hours: morning `09:00`, afternoon `14:00`, evening `19:00`, night `21:00`.
  - Guarantees `resolvedDatetime > now`.
- **Validation ([`server/src/schema.ts`](file:///d:/Context%20aware/Recall/server/src/schema.ts)):**
  - Enforces strict regex `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$` (no `Z`, no offset).
  - Uses Zod schemas to ensure JSON response integrity.
- **Scheduler & Push Notifications ([`server/src/jobs/reminderScheduler.ts`](file:///d:/Context%20aware/Recall/server/src/jobs/reminderScheduler.ts)):**
  - Runs a 1-minute `node-cron`.
  - Queries `collectionGroup("notes")` for `status == "scheduled"` and `notificationSent == false`.
  - Dispatches FCM messages to all user device tokens registered in `users/{uid}/fcmTokens`.
  - Handles RRULE recurrence calculation for `DAILY`, `WEEKLY`, `MONTHLY`, and `YEARLY` tasks.

---

## 5. Build Order & Phase Status Tracking

According to `Claude.md § Build order`, progress is mapped against the 8 implementation phases:

```
[Phase 1: MVP] ──────────────────► COMPLETE  (Notes CRUD, Drift DB, Manual Places)
[Phase 2: Time Intelligence] ────► ACTIVE    (AI Parser, Standalone Server, FCM Reminders)
[Phase 3: Personal Place Triggers] PENDING   (Tracelet Geofences on Manual Places)
[Phase 4: Specific-Place Triggers] PENDING   (One-off Named Places via Google Places API)
[Phase 5: Place Learning] ───────► PENDING   (DBSCAN / Stop-point Clustering)
[Phase 6: Category Triggers] ────► PENDING   (Dynamic rolling geofences: shoe store, etc.)
[Phase 7: Clarification Loop] ───► PENDING   (UI confirmation for low-confidence parses)
[Phase 8: Polish & Recurrence] ──► PENDING   (Snooze, inline editing, complex RRULE)
```

### Detailed Phase Status

- **Phase 1: MVP (Status: Completed)**
  - Notes CRUD with local Drift database.
  - Manual place creation via `MyPlacesScreen` with coordinate and radius definition.
  - Zero AI / zero background tracking dependency at this stage.

- **Phase 2: Time Intelligence (Status: Active / Core Functionality Implemented)**
  - Natural language parsing working via `/parse-note` on Express backend using Gemini 3.5 Flash Lite.
  - Confirmation card UI displayed before committing to database.
  - Server-side cron job dispatches notifications via FCM when reminders mature.
  - Realtime Firestore sync operating under anonymous Firebase authentication.

- **Phase 3: Personal-Place Location Triggers (Status: Up Next)**
  - Add `tracelet` dependency for background geofencing.
  - Map AI-parsed symbolic place references (`PERSONAL` + `"home"`) to `UserPlace` coordinates in local database.
  - Register geofence transitions (`ENTER`, `EXIT`, `DWELL`) with contextual background location permission requests.

---

## 6. Identified Gaps, Risks & Technical Debt

### 6.1 Missing Documentation Artifact: `docs/smart-notes-app-guide.md`
- **Issue:** `Claude.md` repeatedly references `docs/smart-notes-app-guide.md` (e.g., guide §3, §4, §4.1, §4.2, §8, §9, §12) as the master specification. However, the `docs/` directory is missing from the repository.
- **Impact:** Technical details regarding dynamic geofence rotation (guide §4.2) and clarification loops (guide §7) are currently only summarized in `Readme.md` and `Claude.md`.
- **Recommendation:** Formalize and reconstruct the missing design guide within `docs/` based on codebase implementations and existing markdown summaries.

### 6.2 Firestore Composite Index for Cron Scheduler
- **Issue:** The reminder scheduler performs a `collectionGroup("notes")` query filtering on `status == "scheduled"`, `notificationSent == false`, and `resolvedDatetime <= now`.
- **Requirement:** A Firestore composite index on `(status ASC, notificationSent ASC, resolvedDatetime ASC)` is mandatory for this query. Without it, production queries will fail.
- **Status:** The index definition needs to be verified in `firestore.indexes.json`.

### 6.3 FCM Push Delivery & Offline Fallback
- **Issue:** By moving time reminder dispatch entirely to the server via FCM, if an Android device is completely offline (Airplane mode, no cellular/Wi-Fi), the push notification cannot reach the device until connectivity is restored.
- **Recommendation:** Maintain a hybrid approach: for time triggers within the next 24 hours, schedule an exact device alarm via `flutter_local_notifications` (`zonedSchedule`) as a fallback, while retaining FCM for reliable delivery through deep sleep / Doze modes.

### 6.4 Dependency Overrides in Flutter
- **Detail:** In [`pubspec.yaml`](file:///d:/Context%20aware/Recall/pubspec.yaml), `path_provider_android` is constrained to `>=2.2.5 <2.3.0` to prevent pulling in `jni` with CMake / Android NDK requirements.
- **Recommendation:** Keep this override locked until build pipelines are deliberately configured with Android NDK.

---

## 7. Action Plan & Next Steps

1. **Finalize Phase 2 Wrap-Up:**
   - Verify Firestore index creation for `collectionGroup("notes")`.
   - Ensure the Express backend URL configuration (`BACKEND_URL`) is seamlessly supported for local development (Android emulator `10.0.2.2`, physical devices, and deployed containers).

2. **Initiate Phase 3 (Personal-Place Location Triggers):**
   - Add `tracelet` package to `pubspec.yaml`.
   - Update `schema.ts` and `prompt.ts` on the server to recognize symbolic location entities (`locationKind: "personal"`, `locationValue: "home" | "work" | ...`).
   - Implement the local resolver in Flutter: query Drift `user_places` by label and register a `tracelet` geofence with `DWELL` transition.
   - Wire contextual location permissions using `PermissionService` when the first location-tagged note is confirmed.

3. **Reconcile Project Context Files:**
   - Keep this `ANALYSIS.md` as the unified technical architecture record for future development sessions.
