# Atlas

Atlas is a Flutter shopping app for school and office supplies in Turkmenistan. Customers can browse products, search, save favorites, manage a cart, and place orders. The app supports Turkmen and Russian and uses the Atlas API at `https://atlas.com.tm/api`.

- [Official website](https://atlas.com.tm/tk)
- [Atlas on Google Play](https://play.google.com/store/apps/details?id=tm.com.atlas) — Android application ID `tm.com.atlas`

The iOS bundle ID is `com.globus.atlas`. No App Store listing or public GitHub Release has been verified for this repository, so this README does not present an iOS download or an APK download.

## Features

- Browse categories, brands, featured products, and product details.
- Search products and manage favorites and a cart.
- Sign in with a phone number and SMS code.
- Place cash or online payment orders and view order history.
- Receive order notifications through Firebase Cloud Messaging when permission is granted.

## Requirements

- Flutter 3.47.8 and Dart 3.13.7, the toolchain used for the checks in this repository.
- JDK 17 and Android SDK for Android builds. Configure Flutter to use JDK 17 with `flutter config --jdk-dir=/path/to/jdk-17` if Android Studio supplies a newer incompatible JDK.
- Xcode and CocoaPods for iOS builds.
- Existing Firebase configuration in `lib/firebase_options.dart` and the platform Firebase files. Use `flutterfire configure` when connecting a different Firebase project.

## Run and check

```sh
flutter pub get --enforce-lockfile
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release --no-pub
flutter build ios --no-codesign --release --no-pub  # macOS only; no installable IPA
```

The Android release build is unsigned unless a local `android/key.properties` points to the verified Atlas signing key. See [`android/key.properties.example`](android/key.properties.example). Keep the keystore and passwords outside Git. Never publish a debug-signed APK. A repository push does not update Google Play.

See [release readiness](docs/release-readiness.md) for the remaining signing, device, and store checks.
