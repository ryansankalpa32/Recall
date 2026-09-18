# Replace Firebase Cloud Functions with a Standalone Node.js Server

The Firebase Blaze plan is required for Cloud Functions and Secret Manager. This plan converts the `parseNote` backend from a Firebase callable into a plain Express HTTP server, and updates the Flutter client to call it via `http` instead of `cloud_functions`. The server can then be hosted for free on platforms like **Render**, **Railway**, or **Vercel**.

## User Review Required

> [!IMPORTANT]
> **Where will you host the Node.js server?** The server needs to run somewhere publicly accessible. Free options:
> - **Render** — free tier with 750 hours/month (spins down after inactivity, ~30s cold start)
> - **Railway** — $5 free credits/month
> - **Run locally on your machine** — only for development/testing
>
> For now, I'll set it up so you can run it locally with `node server.js` and point your Flutter app at it. You can deploy it to any hosting platform later.

> [!WARNING]
> **Gemini API key will be stored as an environment variable** on the server (via a `.env` file locally). This is less secure than Cloud Secret Manager, but standard for free-tier hosting. Never commit the `.env` file.

> [!IMPORTANT]
> **Firebase Auth, Firestore, and App Check stay unchanged.** Those services work on the free Spark plan. Only Cloud Functions + Secret Manager require Blaze. This change **only** replaces the `parseNote` callable with an HTTP endpoint.

## Proposed Changes

### Backend — Convert `functions/` to a standalone Express server

#### [NEW] [server/package.json](file:///d:/Context%20aware/Recall/server/package.json)
New standalone Node.js project with `express`, `cors`, `dotenv`, `@google/genai`, and `zod` as dependencies. No Firebase SDK required.

#### [NEW] [server/src/index.ts](file:///d:/Context%20aware/Recall/server/src/index.ts)
Express server with a single `POST /parse-note` endpoint. Reuses the same Gemini logic from `functions/src/index.ts`, but:
- Reads `GEMINI_API_KEY` from `process.env` (via `dotenv`) instead of `defineSecret`
- Uses standard Express request/response instead of `onCall`
- CORS enabled for all origins (development) — can be locked down later
- No App Check enforcement (since that's a Firebase-specific mechanism)

#### [NEW] [server/src/prompt.ts](file:///d:/Context%20aware/Recall/server/src/prompt.ts)
Copied as-is from `functions/src/prompt.ts` — no changes needed.

#### [NEW] [server/src/schema.ts](file:///d:/Context%20aware/Recall/server/src/schema.ts)
Copied as-is from `functions/src/schema.ts` — no changes needed.

#### [NEW] [server/tsconfig.json](file:///d:/Context%20aware/Recall/server/tsconfig.json)
TypeScript config adapted from the existing `functions/tsconfig.json`.

#### [NEW] [server/.env](file:///d:/Context%20aware/Recall/server/.env)
Contains `GEMINI_API_KEY=...` and `PORT=5001`. Added to `.gitignore`.

#### [NEW] [server/.gitignore](file:///d:/Context%20aware/Recall/server/.gitignore)
Ignores `node_modules/`, `lib/`, and `.env`.

---

### Flutter Client — Replace Firebase callable with HTTP POST

#### [NEW] [lib/services/backend/http_recall_api_client.dart](file:///d:/Context%20aware/Recall/lib/services/backend/http_recall_api_client.dart)
New `RecallApiClient` implementation that uses `dart:io`'s `HttpClient` (or the `http` package) to `POST` to the Node.js server's `/parse-note` endpoint. Same request/response shape as before, just over plain HTTP instead of a Firebase callable.

#### [MODIFY] [core_providers.dart](file:///d:/Context%20aware/Recall/lib/core/providers/core_providers.dart)
Change `recallApiClientProvider` to return `HttpRecallApiClient` instead of `FirebaseRecallApiClient`. The server URL will be configurable via `--dart-define=BACKEND_URL=http://10.0.2.2:5001` (for Android emulator) or similar.

---

## How to Run

### 1. Start the Node.js server
```bash
cd server
npm install
npm run build
npm start        # or: npm run dev (with auto-reload)
```
Server will listen on `http://localhost:5001`.

### 2. Run the Flutter app
```bash
# For Android emulator (10.0.2.2 is the host machine):
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:5001

# For iOS simulator or web:
flutter run --dart-define=BACKEND_URL=http://localhost:5001

# For a physical device on the same network:
flutter run --dart-define=BACKEND_URL=http://192.168.x.x:5001
```

## Verification Plan

### Manual Verification
1. Start the Node.js server locally
2. Run the Flutter app with the correct `BACKEND_URL`
3. Create a note like "call mum at 4pm" and verify the AI parser returns a correct parsed result
4. Verify the app still works for notes without time expressions
