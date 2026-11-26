// Build-time configuration, set with `--dart-define`. Holds no secrets.

/// What `--dart-define=BACKEND_URL=...` was set to, or empty.
const _backendUrlOverride = String.fromEnvironment('BACKEND_URL');

/// Fallback for local development on the original dev machine's LAN.
/// Anywhere else, pass `--dart-define=BACKEND_URL=http://<host>:5001`
/// (`10.0.2.2` from an Android emulator).
const _devDefaultBackendUrl = 'http://10.10.105.168:5001';

/// Whether [backendUrl] is the dev fallback rather than an explicit setting.
const bool isUsingDefaultBackendUrl = _backendUrlOverride == '';

/// Base URL of the `server/` backend. The single source of truth; nothing
/// else should read `BACKEND_URL`.
const String backendUrl =
    isUsingDefaultBackendUrl ? _devDefaultBackendUrl : _backendUrlOverride;
