// ignore_for_file: lines_longer_than_80_chars
//
// ── HOW TO CONFIGURE ──────────────────────────────────────────────────────────
// Option A (recommended): Install FlutterFire CLI and run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=janarogya-1295f
// This auto-fills every field below.
//
// Option B (manual):
// 1. Firebase Console → Project Settings → Your Apps → Add App (Android)
// 2. Package name: com.janarogya.app
// 3. Download google-services.json → place in android/app/
// 4. Fill apiKey, appId, messagingSenderId below from that file.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for this platform.',
        );
    }
  }

  // ── Android ── get values from google-services.json after adding app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'TODO_ANDROID_API_KEY',
    appId:             'TODO_ANDROID_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId:         'janarogya-1295f',
    storageBucket:     'janarogya-1295f.firebasestorage.app',
  );

  // ── iOS ── get values from GoogleService-Info.plist after adding app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'TODO_IOS_API_KEY',
    appId:             'TODO_IOS_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId:         'janarogya-1295f',
    storageBucket:     'janarogya-1295f.firebasestorage.app',
    iosBundleId:       'com.janarogya.app',
  );

  // ── Web ── get values from Firebase Console → Project Settings → Web App
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'TODO_WEB_API_KEY',
    appId:             'TODO_WEB_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId:         'janarogya-1295f',
    storageBucket:     'janarogya-1295f.firebasestorage.app',
    authDomain:        'janarogya-1295f.firebaseapp.com',
  );
}
