# Web assets

## `sqlite3.wasm` and `drift_worker.js`

Required for `drift` to persist data in the browser — `drift_flutter`'s
`driftDatabase(...)` throws an `ArgumentError` on web unless its `web:`
options point at both (see `lib/data/local/database/app_database.dart`).

Both were copied out of the local pub cache rather than downloaded:

```
<PUB_CACHE>/hosted/pub.dev/drift-<version>/drift_worker.js
<PUB_CACHE>/hosted/pub.dev/drift-<version>/extension/devtools/build/sqlite3.wasm
```

**Refresh these whenever `drift` is upgraded** — the worker is version-matched
to the `drift` package, and a stale one can fail in confusing ways. The
upstream releases are also available from
<https://github.com/simolus3/drift/releases> and
<https://github.com/simolus3/sqlite3.dart/releases>.

## Google Maps

`PlaceEditScreen`'s map-picker needs the Maps JavaScript API on web. Add the
script tag to `index.html` with a browser-restricted key (see the comment
there). Without it the notes screens still work; only the map fails to render.
