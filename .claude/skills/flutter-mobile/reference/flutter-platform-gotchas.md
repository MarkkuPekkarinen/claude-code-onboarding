# Flutter Platform Gotchas — Emulator, DevicePreview, Monorepo

Non-obvious rules for Flutter iOS/Android native config, device_preview automation gates,
and Melos monorepo invocation. These are earned lessons from production incidents — not
obvious from Flutter official docs.

---

## 1. Running Flutter in a Melos Monorepo

**Iron Law:** Never `flutter run -t apps/<app>/lib/main.dart` from the monorepo root.

Flutter walks up the directory tree looking for the nearest `pubspec.yaml`. In a Melos
workspace, it finds the **root** `pubspec.yaml` first — which has no `android/`, no `ios/`,
and no Flutter app structure. The result is cryptic failures like
"AndroidManifest.xml could not be found" or "v1 embedding not supported."

### Correct Invocation

```bash
# Preferred — make targets that regenerate dart_define.json and cd into the app dir
make run-<app>     # or equivalent project-specific make target

# Fallback (only if make unavailable) — cd into the app dir FIRST
cd apps/<app>
flutter run --device-id emulator-5554 \
  --dart-define-from-file=/absolute/path/to/project/dart_define.json
```

### Hard Rules

- Never `flutter run -t apps/<app>/lib/main.dart` from the monorepo root — Flutter
  resolves the project root to the Melos workspace `pubspec.yaml`.
- Never run `flutter pub get` inside an individual app directory — breaks Melos workspace
  symlinks. Always `melos bootstrap` from the repo root.
- Always use an **absolute** path for `--dart-define-from-file` — relative paths resolve
  against CWD, which is ambiguous in monorepos.
- If your project uses dart-define or a `.env`-backed `dart_define.json`, regenerate it
  before each run or you'll get stale config (wrong emulator hostnames, wrong API keys).

### Diagnostic Signals (failure = wrong working directory or stale dart-define)

- `AndroidManifest.xml could not be found`
- `Your app isn't using AndroidX. To avoid potential build failures...`
- `v1 embedding has been deprecated`
- Firebase/backend traffic goes to production hostnames instead of `10.0.2.2` or `localhost`

---

## 2. DevicePreview Android Gate

**Iron Law:** `DevicePreview(enabled: kDebugMode, ...)` silently breaks `adb shell input tap`
and Maestro `tapOn` on Android.

DevicePreview's `InteractiveViewer` wraps the entire app and intercepts all pointer events
before they reach the Flutter widget tree. Screenshots look correct, but no taps register.
Android emulators already provide the correct device frame — DevicePreview adds zero value
and actively blocks automation.

### Required Pattern

```dart
import 'dart:io' show Platform;

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

const bool _devicePreviewRequested = bool.fromEnvironment(
  'DEVICE_PREVIEW',
  defaultValue: false,
);

bool _shouldEnableDevicePreview() {
  if (!kDebugMode) return false;
  if (!_devicePreviewRequested) return false;
  if (kIsWeb) return true;
  return !Platform.isAndroid;
}

void main() => runApp(
  DevicePreview(
    enabled: _shouldEnableDevicePreview(),
    builder: (_) => const MyApp(),
  ),
);
```

### Hard Rules

- Never `DevicePreview(enabled: kDebugMode, ...)` — breaks Android automation
- Never `DevicePreview(enabled: !kReleaseMode, ...)` — same failure mode
- Always require explicit `--dart-define=DEVICE_PREVIEW=true` opt-in (default OFF)
- Always exclude Android (`!Platform.isAndroid`) — even when explicitly requested
- Web is exempt (`kIsWeb` returns true) — safe for responsive design exploration
- iOS is eligible but still requires the `DEVICE_PREVIEW=true` opt-in

### Diagnostic Signal

If `adb shell input tap` or Maestro `tapOn` silently no-op on an Android emulator while
visual screenshots look correct → check `main.dart`. Grep:

```bash
grep -rn "DevicePreview(" apps/*/lib/main.dart
# Every hit must call _shouldEnableDevicePreview() — no exceptions
grep -rn "DevicePreview(enabled: kDebugMode" apps/  # must return 0
grep -rn "DevicePreview(enabled: !kReleaseMode" apps/  # must return 0
```

---

## 3. Android Firebase Emulator — Debug-Only Cleartext Config

**Iron Law:** Android API 28+ blocks cleartext HTTP by default. The Firebase Auth emulator
runs on `10.0.2.2:9099` (the Android emulator's host loopback) over plain HTTP. Without an
explicit allowlist in debug builds only, Firebase calls fail with:

```
[firebase_auth/unknown] An internal error has occurred.
[ Cleartext HTTP traffic to 10.0.2.2 not permitted ]
```

The Firebase Auth Flutter plugin wraps this under the generic `[firebase_auth/unknown]` error
code — making the real cause invisible without digging into logcat.

### Required Files per Android App

**`android/app/src/debug/res/xml/network_security_config.xml`:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

**`android/app/src/debug/AndroidManifest.xml`** (manifest-merger overlay, debug only):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:networkSecurityConfig="@xml/network_security_config"
        tools:replace="android:networkSecurityConfig" />
</manifest>
```

### Hard Rules

- Never put `networkSecurityConfig` in `src/main/AndroidManifest.xml` — this leaks
  cleartext tolerance into release builds.
- Never allowlist any domain other than `10.0.2.2`, `localhost`, `127.0.0.1`.
- `xmlns:tools` MUST be on the root `<manifest>` element, not on `<application>` —
  putting it on `<application>` causes manifest-merger to silently drop the override.
- `tools:replace="android:networkSecurityConfig"` is required — without it, the
  merger complains about an attribute collision.
- Release builds MUST NOT have a `src/release/` counterpart — absence means Android
  falls back to the HTTPS-only default (correct production behavior).
- **Relaunch `flutter run` after creating these files** — the manifest merger runs at
  build time; hot-reload does not pick up native AndroidManifest changes.

### Diagnostic Signal

If logcat shows `W/LocalRequestInterceptor ... Cleartext HTTP traffic ... not permitted`:

1. `android/app/src/debug/AndroidManifest.xml` exists with `tools:replace`?
2. `android/app/src/debug/res/xml/network_security_config.xml` exists?
3. `xmlns:tools` is on root `<manifest>`, not `<application>`?
4. Did you restart `flutter run` (not hot-reload) after file creation?

---

## 4. iOS UIScene Lifecycle — Mandatory Patterns

**Iron Law:** Use the explicit FlutterEngine pattern.
`class SceneDelegate: FlutterSceneDelegate { }` produces a black screen.

### Required SceneDelegate

```swift
import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private var engine: FlutterEngine?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let flutterEngine = FlutterEngine(name: "main")
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    engine = flutterEngine
    let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = controller
    window?.makeKeyAndVisible()
  }

  // Firebase Auth OAuth callback — must use Auth.auth().canHandle(), NOT AppDelegate forwarding
  // Firebase Auth is registered with the FlutterEngine's plugin registry, not AppDelegate.
  // Forwarding via UIApplication.shared.delegate?.application?(:open:options:) silently drops URLs.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      if Auth.auth().canHandle(context.url) { return }
    }
  }
}
```

### Required AppDelegate

```swift
@objc class AppDelegate: FlutterAppDelegate {
  override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // MUST call super — initializes FlutterPluginAppLifeCycleDelegate
    _ = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    return true
  }
}
```

### Hard Rules

- Never `class SceneDelegate: FlutterSceneDelegate { }` — produces a black screen
- `FlutterEngine.run()` MUST be called BEFORE `GeneratedPluginRegistrant.register(with:)`
- Always call `super.application(...)` in AppDelegate — omitting means plugin lifecycle
  hooks never fire
- For Firebase Auth OAuth: call `Auth.auth().canHandle(context.url)` directly in
  `scene(_:openURLContexts:)` — do NOT forward via AppDelegate (the plugin is registered
  with the FlutterEngine's plugin registry, not AppDelegate's lifecycle delegate)

### Info.plist Requirements

- Remove `UIMainStoryboardFile` key — prevents dual-engine conflict with UIScene
- Remove `UISceneStoryboardFile` key — same reason
- Keep `UIApplicationSceneManifest` pointing to the `SceneDelegate` class
- If using Firebase Auth, add `CFBundleURLTypes` with the Firebase Auth URL scheme

### Melos `dependency_overrides` — Root Only

`dependency_overrides` for shared packages (e.g. `firebase_core_platform_interface`)
MUST live **only** in the root `pubspec.yaml`. Melos rejects duplicate overrides across
workspace packages — adding the same override to an individual app's `pubspec.yaml`
causes `melos bootstrap` to fail with a conflict error.

```yaml
# ✅ ROOT pubspec.yaml only
dependency_overrides:
  firebase_core_platform_interface: 5.4.1

# ❌ NEVER in apps/<app>/pubspec.yaml
```

---

## Pre-Commit Checklist (Platform/Emulator)

```
Monorepo flutter run
  □ Used make target or cd apps/<app> — never flutter run -t from monorepo root
  □ dart-define file regenerated from .env before the run
  □ Absolute path used for --dart-define-from-file

DevicePreview
  □ grep -rn "DevicePreview(" apps/*/lib/main.dart → every hit calls _shouldEnableDevicePreview()
  □ grep -rn "DevicePreview(enabled: kDebugMode" apps/ → must return 0
  □ grep -rn "DevicePreview(enabled: !kReleaseMode" apps/ → must return 0

Android Cleartext Config (Firebase emulator)
  □ android/app/src/debug/AndroidManifest.xml has networkSecurityConfig + tools:replace
  □ android/app/src/debug/res/xml/network_security_config.xml allowlists ONLY 10.0.2.2, localhost, 127.0.0.1
  □ grep -r "networkSecurityConfig" android/app/src/main/ → must return 0
  □ grep -r "cleartextTrafficPermitted.*true" android/app/src/release/ → must return 0
  □ xmlns:tools on root <manifest>, not <application>

iOS UIScene
  □ SceneDelegate extends UIResponder (NOT FlutterSceneDelegate)
  □ FlutterEngine.run() called BEFORE GeneratedPluginRegistrant.register(with:)
  □ AppDelegate.application(_:didFinishLaunchingWithOptions:) calls super
  □ Info.plist has NO UIMainStoryboardFile or UISceneStoryboardFile keys
  □ dependency_overrides NOT present in any individual app pubspec.yaml
```
