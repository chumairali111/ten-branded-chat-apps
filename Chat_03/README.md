# Updated Flutter client

Current setup and feature scope are in `../UPGRADE_RUN_ROMAN_URDU.md` and `../docs/MEDIA_CALLS_UPGRADE.md`. This update adds native/browser WebRTC calling while the app is open, PCM/WAV voice notes, media playback, image/video stories, viewer lists, profile photos and password-dialog/lock fixes. The baseline README below is retained for reference; its previous statements about missing call/media implementation are superseded by the upgrade guide. Full platform build validation is still required.

# Flutter client

This is an independent client for the existing Flask/SQLite application. It does not connect to WhatsApp or Meta accounts. The original JavaScript browser application is still available.

## Requirements and initial setup

Install a current stable Flutter SDK (Flutter 3.24 / Dart 3.5 or newer) and platform tooling for the targets you intend to run. This workspace did not include a Flutter/Dart SDK when this client was added, so platform projects are generated on the development machine:

```powershell
cd flutter_app
flutter create --platforms=android,ios,web .
flutter pub get
```

The `flutter create` command adds the Android/iOS/Web runner scaffolding without replacing this client's Dart sources. iOS builds require macOS and Xcode.

Start the Flask backend in a separate terminal from the repository root:

```powershell
.\.venv\Scripts\python.exe run.py
```

For local Flutter Web development, run the backend and browser on the same host name (`127.0.0.1`) so the backend's `SameSite=Strict` cookie remains same-site. Flutter Web uses a different port, so allow that exact development origin:

```powershell
$env:WEB_ALLOWED_ORIGINS = "http://127.0.0.1:5173"
.\.venv\Scripts\python.exe run.py
```

In a second terminal:

```powershell
cd flutter_app
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:5000/api
```

For the Android emulator the default API URL is `http://10.0.2.2:5000/api`. For a physical Android device, use the development computer's LAN address, e.g. `--dart-define=API_BASE_URL=http://192.168.1.10:5000/api`. To expose the development Flask server to your trusted LAN temporarily, run `$env:HOST="0.0.0.0"` before `.\.venv\Scripts\python.exe run.py`; keep the firewall enabled and restore the loopback default after testing. For iOS Simulator, provide a reachable backend URL such as `--dart-define=API_BASE_URL=http://127.0.0.1:5000/api`. Devices must be able to reach the backend.

Flutter Web defaults to the current page origin plus `/api`. The development command above overrides it. When frontend and API use different origins, configure the backend with the exact web origin, including scheme and port:

The sample command above configures `WEB_ALLOWED_ORIGINS` before starting the API. Replace it with the exact origin used by your browser during development.

Credentialed CORS is restricted to this explicit allowlist. Do not use `*`. Production is best served from the same origin, over HTTPS. Configure secure cookies (`COOKIE_SECURE=1`) when HTTPS is enabled. Do not expose the development server directly to the public internet.

## Platform permissions

QR scanning requires camera permission. After generating platform scaffolding, add `<uses-permission android:name="android.permission.CAMERA"/>` to the Android manifest and verify the plugin's required settings. Add `NSCameraUsageDescription` to iOS `Info.plist`. iOS builds require a Mac. Microphone/camera capture for native calls is not implemented in this Flutter client and should not be enabled as a claim of calling support.

For example, Android's generated `android/app/src/main/AndroidManifest.xml` should contain `<uses-permission android:name="android.permission.CAMERA"/>` directly under `<manifest>`. Add an `NSCameraUsageDescription` string such as `Camera access is used to scan a linked-device sign-in QR code.` to `ios/Runner/Info.plist`. Review each platform's merged permissions before release.

Plain HTTP is for local development only. Use HTTPS for real devices and production; do not enable Android cleartext globally to work around a network configuration problem.

Native session tokens are stored through `flutter_secure_storage`; they are not placed in browser storage, QR codes, or URL parameters. Web sign-in uses the backend's HTTP-only session cookie. Pairing challenge secrets are short-lived and single-use, and device approval must be explicitly confirmed on an authenticated client.

## Validation

```powershell
cd flutter_app
flutter analyze
flutter test
flutter build web
flutter build apk
```

For iOS, build on macOS with `flutter build ios`. Verify camera pairing on real supported devices and verify web responsiveness in desktop and mobile browser sizes. The available project environment did not provide Flutter/Dart, so these commands must be run in a configured Flutter environment before release.

## Current client scope

Implemented client flows include account registration/login, responsive chat list/search/filters, direct/group creation, text messages, read receipts, reply/reaction/star/edit/delete, file upload, chat favourite/archive/mute/media visibility and privacy controls, text status, communities, device session revocation, and QR device pairing.

The Flutter app does not yet implement native WebRTC media calls, attachment download/export, location and voice-note capture, complete group administration, custom lists, offline push/background delivery, or all features available in the JavaScript frontend. The existing backend/browser call feature still requires STUN/TURN configuration for internet connectivity. There is no E2E encryption, phone OTP, channels, group calls, or real WhatsApp account linking.
