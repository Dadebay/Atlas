// File generated from google-services.json
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvF2zBHJtuCd15sUGJsEouQQDpAHuxhZc',
    appId: '1:51094765462:android:e1a10655beec971e20e7b7',
    messagingSenderId: '51094765462',
    projectId: 'atlas-1e8f0',
    storageBucket: 'atlas-1e8f0.firebasestorage.app',
  );

  // iOS üçin GoogleService-Info.plist goşanyňyzdan soň dolduryň
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAvF2zBHJtuCd15sUGJsEouQQDpAHuxhZc',
    appId: '1:51094765462:ios:e1a10655beec971e20e7b7',
    messagingSenderId: '51094765462',
    projectId: 'atlas-1e8f0',
    storageBucket: 'atlas-1e8f0.firebasestorage.app',
  );
}
