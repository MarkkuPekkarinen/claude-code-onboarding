# Flutter Security Hardening & Privacy Compliance

For general code security (OWASP Top 10, injection, auth, secrets) use the `security-reviewer` agent instead. This reference focuses on **Flutter-specific** security and **mobile privacy compliance**.

## Flutter Client-Side Security

### Secure Storage

- Use `flutter_secure_storage` for sensitive data — never `SharedPreferences` for secrets
- No hardcoded API keys, secrets, or credentials in Dart code
- Obfuscate release builds (`--obfuscate --split-debug-info`)

### Network Security

- Certificate pinning for API connections
- No HTTP traffic in production (enforce HTTPS)
- API keys served via backend proxy, not embedded in app

### Build Security

- Obfuscate release builds: `flutter build apk --obfuscate --split-debug-info=build/symbols`
- ProGuard/R8 enabled for Android
- Strip debug symbols in release

### Deep Link Security

- Validate deep link parameters before processing
- Don't expose sensitive routes via deep links
- Use App Links (Android) / Universal Links (iOS) over custom schemes

## Firebase App Check

App Check verifies that requests to your Firebase backend come from a legitimate build of your app — not an emulator, a forged client, or a script. It protects **all** Firebase services (Auth, Storage, Cloud Functions, Realtime Database) regardless of which database you use.

### Setup in `main.dart`

```dart
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activate App Check before any other Firebase service
  await FirebaseAppCheck.instance.activate(
    // iOS: DeviceCheck (production) — requires Apple DeviceCheck entitlement
    // Android: Play Integrity (production) — requires app signed and on Play Store
    // Use debug providers ONLY in debug builds
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  runApp(const ProviderScope(child: App()));
}
```

### `pubspec.yaml`
```yaml
dependencies:
  firebase_app_check: ^0.3.2
```

### Rules

- Activate App Check **before** calling any other Firebase service — wrong order causes silent failures
- `kDebugMode` guard is mandatory — debug provider bypasses attestation for local development; shipping it to production defeats the purpose
- Add `FirebaseAppCheck` to the pre-release security checklist
- No code changes needed in repositories or services — App Check operates at the Firebase SDK network layer

### Pre-Release Checklist Addition

Add to the checklist in this file:
- [ ] Firebase App Check activated with platform-specific production providers (DeviceCheck / Play Integrity)
- [ ] Debug provider guard (`kDebugMode`) confirmed — debug provider NOT active in release builds

## Privacy Compliance

### GDPR Requirements

- **Lawful Basis** — document the legal basis for each data type
- **Data Minimization** — collect only what's necessary
- **Consent Management** — granular consent with easy withdrawal
- **Data Subject Rights** — implement export, deletion, rectification, portability
- **Data Retention** — automated cleanup policies; never store data longer than needed

### CCPA Requirements

- **Consumer Rights** — right to know, delete, and opt out of data sales
- **Do Not Sell** — respect opt-out preferences
- **Privacy Preferences** — per-user opt-out tracking with audit history

## Pre-Release Security Checklist

- [ ] Zero hardcoded secrets in codebase
- [ ] `flutter_secure_storage` used for all sensitive data
- [ ] Release builds obfuscated
- [ ] Certificate pinning configured
- [ ] GDPR consent flow implemented
- [ ] Data export/deletion endpoints functional
- [ ] Privacy policy URL accessible from app
- [ ] Dependencies scanned for known vulnerabilities

## Incident Response (Mobile-Specific)

1. **Contain** — force app update or feature flag to disable compromised flow
2. **Investigate** — collect crash logs, analyze scope of data exposure
3. **Notify** — user notification + regulatory notification within required timeframes (72h GDPR)
4. **Remediate** — push hotfix, revoke compromised tokens, rotate keys
5. **Review** — post-incident report, update security policies
