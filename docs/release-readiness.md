# Atlas release readiness

Checked on 8 November 2026 with Flutter 3.47.8 / Dart 3.13.7. This repository is the Flutter client; it does not contain the Atlas API, website deployment, backups, or store-console configuration.

## Verified

- The [Atlas website](https://atlas.com.tm/tk) returned HTTPS 200. The [Google Play listing](https://play.google.com/store/apps/details?id=tm.com.atlas) exists and matches Android application ID `tm.com.atlas`.
- The project lockfile was refreshed for the current Flutter SDK. Formatting, analysis, and all tests passed. The Android release Gradle task passed with JDK 17; its output is unsigned without a local verified key. The iOS release compiled with code signing disabled.
- The payment WebView no longer bypasses TLS certificate checks or accepts HTTP pages. Payment-return URLs must use HTTPS and an exact approved host. A confirmed order is not treated as a failed POST when later payment-link parsing fails; an unconfirmed payment is not shown as paid.
- A missing cart price is displayed as unknown and blocks checkout instead of becoming a zero-price order. Debug logs no longer include order bodies, payment URLs, search responses, or FCM tokens. Unused `image_picker` and obsolete FCM helper classes were removed.
- Android release builds no longer use the debug signing key. The Gradle wrapper is tracked for clean checkouts, and CI checks both Android and unsigned iOS builds.

## Before a store or GitHub binary release

- Confirm the version currently in Play Console and raise `versionCode` above it before uploading an update. The source currently declares `1.0.0+1`; the public Play page does not expose its version code.
- A candidate keystore exists in secure storage under `Project Keys/12. Atlas`. Its alias is readable, but the adjacent `key.properties` points to a nonexistent `storeFile`. Candidate certificate SHA-256: `AA:80:B9:69:2B:04:70:E7:57:08:21:9F:E1:8F:0C:F8:B6:B1:57:14:5C:68:F3:5C:7B:11:5B:67:F5:05:92:E1`. Compare it with the **upload certificate** in Play Console before signing an AAB. For a directly installable APK that must update the Play-installed app, compare with the **app signing certificate** too. Keep passwords and keys outside Git.
- Test startup, sign-in, catalog, cart, online payment return, order history, notifications, and upgrade on physical Android and iOS devices. No Android device was attached for this check. Do not spend money in a production payment test.
- Confirm the backend's duplicate-order/idempotency behavior, including a lost POST response. The client now handles a known successful POST more safely, but it cannot prove that an ambiguous network failure did not create an order. Review the Google Play description, which mentions user-posted listings that were not found in this client's main flows.
- Review token storage: the JWT is currently in `get_storage`, not an encrypted credential store. Verify privacy disclosures for Firebase messaging, account data, and payment flows. Check accessibility and larger-text behavior on devices.
- The iOS bundle ID is `com.globus.atlas`; no App Store listing, provisioning, or signed IPA was verified. The current iOS build uses CocoaPods for plugins that do not yet support Swift Package Manager.
- The Gradle, Android Gradle Plugin, and Kotlin versions pass now but emit future-support warnings. Upgrade them as a separate, tested change. The backend owner must supply API health, deployment, backup/restore, and rollback procedures.

No signed APK, Play upload, or GitHub Release is published by this repository update. Create a version tag and a Release only for a verified build from the exact tagged commit; include a checksum and installation notes if a signed direct-download APK is appropriate.
