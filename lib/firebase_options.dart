// lib/firebase_options.dart
// ⚠️  THIS FILE IS A STUB.
// Run `flutterfire configure` to generate real Firebase credentials.
// Instructions:
//   1. Go to https://console.firebase.google.com and create a project.
//   2. Enable Email/Password authentication under Authentication > Sign-in methods.
//   3. In your terminal, run:
//        flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//   4. This file will be auto-replaced with real credentials.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ⚠️  Replace all placeholder values below by running: flutterfire configure

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtG0jkBpS7VpPMa36ISDVucyzDozzFYw0',
    appId: '1:137562470855:web:202a115ad9a93d671fc1e2',
    messagingSenderId: '137562470855',
    projectId: 'personal-os-c833e',
    authDomain: 'personal-os-c833e.firebaseapp.com',
    storageBucket: 'personal-os-c833e.firebasestorage.app',
    measurementId: 'G-VMT7CX6PM6',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.personalOs',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.personalOs',
  );
}
