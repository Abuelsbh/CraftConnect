// Copy your actual options from FlutterFire CLI output into this file.
// This placeholder enables initializing Firebase on non-Android platforms.

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android uses google-services.json; no options needed here typically.
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  // PLACEHOLDER VALUES: Replace with real values from your Firebase project.
  static const FirebaseOptions web =  FirebaseOptions(
    apiKey: "AIzaSyDVnOZ6BE0oh_L6TnjbB5tvoQu2HqVNn9w",
    authDomain: "parking-4d91a.firebaseapp.com",
    databaseURL: "https://parking-4d91a-default-rtdb.firebaseio.com",
    projectId: "parking-4d91a",
    storageBucket: "parking-4d91a.appspot.com",
    messagingSenderId: "321053041363",
    appId: "1:321053041363:web:011300e9b65e1f70802a26",
    measurementId: "G-13PPVDSXG9"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNAvTpA-3VdzxdcfV-VBU80HJCU15unfk',
    appId: '1:321053041363:android:462eff233e51679a802a26',
    messagingSenderId: '321053041363',
    projectId: 'parking-4d91a',
    storageBucket: 'parking-4d91a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNAvTpA-3VdzxdcfV-VBU80HJCU15unfk',
    appId: '1:321053041363:ios:462eff233e51679a802a26',
    messagingSenderId: '321053041363',
    projectId: 'parking-4d91a',
    iosBundleId: 'com.pix.fix',
    storageBucket: 'parking-4d91a.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCNAvTpA-3VdzxdcfV-VBU80HJCU15unfk',
    appId: '1:321053041363:ios:462eff233e51679a802a26',
    messagingSenderId: '321053041363',
    projectId: 'parking-4d91a',
    iosBundleId: 'com.pix.fix',
    storageBucket: 'parking-4d91a.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WINDOWS_API_KEY',
    appId: 'REPLACE_WITH_WINDOWS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_LINUX_API_KEY',
    appId: 'REPLACE_WITH_LINUX_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
  );
}
