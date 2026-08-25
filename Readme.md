# Threadline

Notes that know where and when to remind you. Instead of manually setting a time or pinning a location for every reminder, you write a note in plain language — "I need to get shoes," "homework in maths," "work to do at 4pm" — and the app figures out the trigger itself.

## Table of contents
- [Overview](#overview)
- [Why this exists](#why-this-exists)
- [Key features](#key-features)
- [How it works](#how-it-works)
- [Data model](#data-model)
- [Tech stack](#tech-stack)
- [Permissions](#permissions)
- [Project status](#project-status)
- [Known challenges](#known-challenges)
- [Related docs](#related-docs)
- [License](#license)

## Overview

Three examples of what this app does that a normal notes/reminders app doesn't:

- **"I need to get shoes"** → notifies you when you walk into *any* shoe store, not just one you pinned in advance.
- **"Homework in maths"** → notifies you when you get home — without you ever telling the app where "home" is.
- **"Work to do at 4pm"** (no date mentioned) → the app infers *today* at 4pm if that time hasn't passed yet, or tomorrow if it has.

## Why this exists

Existing note and reminder apps (Google Keep, Apple Reminders, Todoist, TickTick) support location triggers, but only as a specific address the user pins manually — none of them generalize to "any place of this type," and none of them learn your home or work location from behavior. This app is built specifically around that gap: AI resolves the trigger from free text, location triggers work on both learned personal places and generic categories, and ambiguous input gets clarified instead of silently guessed.

## Key features

- Free-text note capture — no forms, no manual date/location pickers
- AI parsing layer that extracts task, trigger type, location, and time from plain language
- Implicit date/time resolution (e.g. "4pm" with no date → most likely today or tomorrow)
- Location triggers on three levels: learned personal places (home/work), generic categories (shoe store, pharmacy), and specific named places
- Enter/exit/dwell-aware geofencing to avoid false positives from just driving past a place
- Confidence-based clarification — low-confidence guesses prompt a quick confirmation instead of a wrong reminder
- Actionable notifications (done / snooze / open note)

## How it works

```
New note (free text)
        │
        ▼
   AI parser  ──►  extracts task + trigger_type + time/location entities
        │
   ┌────┴────┐
   ▼         ▼
Location   Time
engine     engine
   │         │
   └────┬────┘
        ▼
   Notification
```

- **Location engine** — resolves against `UserPlace` (learned home/work) for personal triggers, or queries the Places API and manages a rolling set of geofences for category triggers.
- **Time engine** — resolves relative/implicit time expressions against the current datetime, then schedules via `AlarmManager` (exact) or `WorkManager` (deferred).

## Data model

**Note**
| Field | Type | Notes |
|---|---|---|
| `raw_text` | String | What the user typed |
| `task_description` | String | AI-cleaned task |
| `trigger_type` | enum | `LOCATION`, `TIME`, `BOTH`, `NONE` |
| `location_kind` | enum | `PERSONAL`, `CATEGORY`, `SPECIFIC` |
| `geofence_transition` | enum | `ENTER`, `EXIT`, `DWELL` |
| `resolved_datetime` | Timestamp | After disambiguation |
| `recurrence_rule` | String? | Null for one-off, RRULE for repeating |
| `confidence` | Float | From the AI parse |
| `status` | enum | `PENDING`, `SCHEDULED`, `NOTIFIED`, `DONE`, `NEEDS_CLARIFICATION` |

**UserPlace**
| Field | Type | Notes |
|---|---|---|
| `label` | String | `home`, `work`, custom |
| `lat` / `lng` | Double | |
| `radius_m` | Int | Geofence radius |
| `source` | enum | `LEARNED` or `MANUAL` |

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter (Dart) |
| Local storage | `drift` (SQLite) or `sqflite` |
| Scheduling | `workmanager` (deferred) + `flutter_local_notifications` exact-alarm triggers |
| Location & geofencing | `tracelet` (free, open-source — see the guide for the maturity tradeoff vs the paid alternative) |
| Notifications | `flutter_local_notifications` |
| Permissions | `permission_handler` |
| Places data | Google Places API |
| AI parsing | Backend endpoint → LLM API (structured/tool-use output) |
| Backend | Thin proxy service (holds API keys, proxies Places calls) |

## Permissions

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — geofencing and place matching
- `ACCESS_BACKGROUND_LOCATION` — required for triggers to fire when the app isn't open; requires a clear in-app disclosure before requesting, per Play Store policy
- `SCHEDULE_EXACT_ALARM` (Android 12+) — for precise time-based reminders
- Internet — AI parsing calls and Places API lookups

## Project status

- [ ] MVP — manual notes, manual time reminders
- [ ] Time intelligence — AI-parsed free-text time expressions
- [ ] Specific-place location triggers
- [ ] Personal-place learning (home/work via clustering)
- [ ] Category-based location triggers (dynamic geofencing)
- [ ] Confidence & clarification loop
- [ ] Polish — snooze/done actions, manual trigger editing

## Known challenges

- Android caps geofences at 100 per app — category triggers must stay "nearby only," refreshed as the user moves
- `DWELL` transitions (not raw `ENTER`) needed to avoid false positives from driving past a place
- Places API cost/quota requires caching and refresh throttling
- Continuous location tracking drains battery — use significant-location-change patterns, not polling
- Low-confidence AI parses need a clarification path rather than a silent (possibly wrong) reminder

