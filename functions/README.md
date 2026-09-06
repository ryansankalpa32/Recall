# Recall backend proxy

The thin proxy required by `Claude.md`: **no LLM key ever ships in the Flutter app**.
This holds the Gemini key and exposes one callable, `parseNote`, used by Phase 2
(time intelligence).

`/places/nearby` does not exist yet — it is Phase 4, and
`FirebaseRecallApiClient.placesNearby` still throws `UnimplementedError`.

## Layout

| File | What it is |
|---|---|
| `src/index.ts` | The `parseNote` callable — validation, the Gemini call, and the failure paths |
| `src/prompt.ts` | The system instruction, including the today/tomorrow resolution rules |
| `src/schema.ts` | Request/response schemas, and the JSON Schema handed to the model |
| `test/schema.test.ts` | Pure validation tests — no API calls, no cost |

## The contract

Request:

```jsonc
{
  "rawText": "call mum at 4pm",
  "now": "2026-09-05T18:30:00",   // ISO-8601 local wall-clock, no offset, no Z
  "timeZone": "Asia/Colombo"       // IANA
}
```

Response:

```jsonc
{
  "taskDescription": "call mum",
  "triggerType": "time",                        // "time" | "none"
  "locationKind": null,                         // always null until Phase 3
  "locationValue": null,                        // always null until Phase 3
  "resolvedDatetime": "2026-09-06T16:00:00",    // null when triggerType is "none"
  "recurrenceRule": null,                       // always null until Phase 8
  "confidence": 0.93
}
```

Two things about this that are load-bearing:

- **`now` is a request parameter, not the server's clock.** That is what makes the
  today/tomorrow rule testable — pin `now` and the whole rule becomes
  deterministic.
- **Datetimes carry no offset and no `Z`.** `DateTime.parse` on the Dart side
  returns a *local* `DateTime` only for that shape, and `SchedulingService` feeds
  it to `tz.TZDateTime.from(..., tz.local)`. A stray `Z` would shift every
  reminder by the device's UTC offset, so both sides reject it.

The model is never asked for `locationKind`, `locationValue`, or `recurrenceRule`
— they are absent from its schema entirely, so it *cannot* emit a Phase 3+
trigger. The callable fills them in as null. See the comment in `schema.ts`.

## Setup

```bash
npm install

# Point the repo at your Firebase project (creates .firebaserc)
firebase use --add

# Store the Gemini key — never in source, never in .env
firebase functions:secrets:set GEMINI_API_KEY
```

## Develop

```bash
npm run build          # tsc
npm test               # build + validation tests (no API calls)
npm run serve          # build + functions emulator on :5001
npm run deploy         # firebase deploy --only functions
```

To point the app at the emulator, add this to `FirebaseRecallApiClient`'s
constructor while developing:

```dart
FirebaseFunctions.instanceFor(region: 'us-central1')
    .useFunctionsEmulator('localhost', 5001);
```

## App Check

`enforceAppCheck: true` is set on the callable. Without it this endpoint is an
open, paid Gemini relay for anyone who finds the URL — **do not ship with it
off.**

The consequence is that emulator and CI runs need debug providers. In
`lib/bootstrap.dart` swap the production providers for
`AndroidDebugProvider()` / `AppleDebugProvider()` during local development, and
register the printed debug token in the Firebase console.

## Cost

This callable is the only paid path in the app. It runs
`gemini-3.8-flash` at `thinking_level: "low"` with `max_output_tokens: 512`, and
`rawText` is capped at 1000 characters, so a single parse is small and bounded.
`gemini-3.5-flash-lite` is the step-down if volume ever justifies it.

## Testing the prompt itself

`npm test` deliberately covers validation only — it never calls Gemini, so it is
free and runs in CI. Prompt-behaviour tests (does "4pm" actually roll to
tomorrow after 4pm?) cost money on every run and are best kept as a separate,
opt-in script gated behind an env var.
