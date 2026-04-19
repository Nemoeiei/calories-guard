# Android Release Keystore — Setup & Release Runbook

> Covers PRODUCTION_READINESS.md task #5.
> Audience: the engineer cutting the first signed APK / AAB for
> `com.caloriesguard.app`. Plan on ~20 minutes. Some steps require a real
> human (passwords, secure backup) and cannot be automated.

---

## Why a dedicated release keystore

The Android package is identified by `(applicationId, signing certificate)`.
Once an APK is installed on a device — or uploaded to Google Play — you
cannot change the certificate without uninstalling or re-publishing as a
different package.

The repo currently ships with the Flutter debug key (`~/.android/debug.keystore`,
alias `androiddebugkey`, password `android`). That is **fine for `flutter
run`** but unacceptable for beta distribution:

- Debug certs are common (many developers share the exact same file), so the
  signature is not a real identity.
- You cannot upgrade an app from debug-signed to release-signed on a user's
  phone; the install fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- Google Play Console rejects APKs signed with the debug key.

So: before any tester installs the APK, generate a release keystore, sign
with it, and **never rotate the private key** afterward.

---

## Step 1 — Generate the keystore (one time)

Run on the build machine (developer laptop, not in CI — the .jks must never
hit the repo or CI logs).

```bash
# From flutter_application_1/android/
keytool -genkey -v \
  -keystore ./app/upload-keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storetype JKS
```

`keytool` prompts for:

- **Keystore password** — store-wide. Pick a strong random string (≥ 16
  chars). Save it in a password manager, not on disk.
- **Key password** — per-alias. Use the SAME string as the keystore
  password unless you have a reason to separate them. Gradle config assumes
  they match.
- **Common Name (first/last) / Org / City / Country** — real values. Google
  Play displays them on the developer record.

Output: `flutter_application_1/android/app/upload-keystore.jks` (~2 KB).

Verify:

```bash
keytool -list -v -keystore ./app/upload-keystore.jks -alias upload
# Should print: Alias name: upload
#               Valid from: ... until: ... (≥ 25 years)
#               Certificate fingerprints: SHA256 = <64-hex>
```

Record the SHA-256 fingerprint — you need it to enable Google Sign-In /
Firebase later.

---

## Step 2 — Create `key.properties`

Still inside `flutter_application_1/android/`:

```bash
cp key.properties.example key.properties
```

Then edit `key.properties`:

```properties
storePassword=<the password from step 1>
keyPassword=<same as storePassword unless you split them>
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Paths resolve relative to the `android/` directory because `rootProject.file()`
in `build.gradle.kts` anchors there. `app/upload-keystore.jks` is the
canonical location — keep it under `android/app/` so `file(storeFile)`
finds it.

Confirm it is ignored:

```bash
git status
# key.properties and upload-keystore.jks must NOT appear in "Untracked files"
```

Root `.gitignore` already excludes:

- `flutter_application_1/android/key.properties`
- `flutter_application_1/android/*.jks`
- `flutter_application_1/android/app/*.jks`

---

## Step 3 — Back up the keystore (critical)

If you lose `upload-keystore.jks` or the password, you cannot publish
updates to existing installs. Ever.

- Copy the .jks to at least **two** locations outside the repo:
  - Password manager attachment (1Password, Bitwarden, KeePassXC)
  - Encrypted cloud drive folder (Google Drive + 2FA, or an encrypted
    disk image)
- Also back up the passwords separately from the file.

Test the backup: delete the local .jks, restore from backup, run Step 4.
If it signs successfully, your backup works. Restore to `app/upload-keystore.jks`.

---

## Step 4 — Build and verify a signed APK

```bash
# From flutter_application_1/
flutter clean
flutter pub get

flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-railway>.up.railway.app \
  --dart-define=SENTRY_DSN=<flutter-sentry-dsn>
```

Inspect the signing:

```bash
# Find the APK
ls build/app/outputs/flutter-apk/app-release.apk

# Confirm it was signed with the upload keystore, not the debug key
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
# SHA256 fingerprint must match what you recorded in Step 1.

# Confirm versionCode / applicationId
$ANDROID_HOME/build-tools/<latest>/aapt dump badging \
  build/app/outputs/flutter-apk/app-release.apk | head -3
# package: name='com.caloriesguard.app' versionCode='<N>' versionName='<X.Y.Z>'
```

Install on a real device (not an emulator — beta testers will be on real
hardware):

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Launch the app, hit a login, record a meal, upload an image. If any of
those fail, fix before distributing.

---

## Step 5 — Distribute (Firebase App Distribution)

Once the signed APK boots:

```bash
# Assumes firebase CLI + App Distribution plugin installed and logged in
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app <firebase-android-app-id> \
  --groups "beta-testers" \
  --release-notes "First signed build. <short changelog>"
```

Testers get an email from Firebase with an install link. They must install
the Firebase App Tester app first; after that every new build shows up
automatically.

---

## Step 6 — For later: upgrading to Play Store

When you eventually publish to the Play Store:

1. In Play Console → Setup → App signing → **Use Play App Signing**.
2. Upload `upload-keystore.jks` (and password) — this becomes your *upload*
   key. Google holds the *app signing* key and re-signs on release.
3. From that point, every new AAB/APK must be signed with this same
   upload key; Google re-signs with the Play-managed key before shipping
   to devices.

If you lose the upload key after enrolling, Google can reset it (24-hour
waiting period, requires the recovery email on the Play account). That's
less catastrophic than the old days, but still — don't lose it.

---

## Recovery scenarios

| Scenario | Fix |
|---|---|
| `Keystore was tampered with, or password was incorrect` during build | Your passwords in `key.properties` don't match the .jks. Retrieve from password manager and correct. |
| Lost `upload-keystore.jks` but still have password | Restore from backup (Step 3). If no backup: for App Distribution, generate a new keystore + re-onboard testers (they must uninstall old build). For Play Store, use the key reset flow. |
| Lost the password too | Same as above — you cannot recover the .jks itself without the password. |
| CI fails because `key.properties` isn't present | CI should never sign release builds; keep release signing on the developer laptop. If you need CI-signed builds later, inject the .jks and passwords via CI secrets — NEVER commit them. |

---

## Verification checklist (task #5)

- [ ] `flutter_application_1/android/app/upload-keystore.jks` exists locally
      and is excluded from git.
- [ ] `flutter_application_1/android/key.properties` exists locally and is
      excluded from git.
- [ ] `flutter build apk --release` produces an APK; `keytool -printcert
      -jarfile` shows the upload keystore fingerprint (not the debug one).
- [ ] At least two offline backups of the .jks exist in separate locations.
- [ ] Passwords stored in a password manager (not in the repo, not in
      plaintext files on the build machine).
- [ ] Fingerprint recorded for later Firebase / Google Sign-In setup.
