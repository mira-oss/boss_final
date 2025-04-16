import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration options for the different Firebase services for your project
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS platform is not configured. Please create configuration manually.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS platform is not configured. Please create configuration manually.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not supported by Firebase.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDEs27nuOGJRyzULEV-u93rcbarmeEnAEg",
    appId: "1:210930223753:web:ad1a622a9f76fe455d1458",
    messagingSenderId: "210930223753",
    projectId: "bossfinal-581aa",
    authDomain: "bossfinal-581aa.firebaseapp.com",
    storageBucket: "bossfinal-581aa.firebasestorage.app",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDvmizpBNOsOUi3PvsSycawRRl8hE076vw",
    appId: "1:210930223753:android:6a585ba71221de4a5d1458",
    messagingSenderId: "210930223753",
    projectId: 'bossfinal-581aa',
    storageBucket: 'bossfinal-581aa.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDEs27nuOGJRyzULEV-u93rcbarmeEnAEg',
    appId: '1:210930223753:web:5e9ca7b9301dcc205d1458',
    messagingSenderId: '210930223753',
    projectId: 'bossfinal-581aa',
    authDomain: 'bossfinal-581aa.firebaseapp.com',
    storageBucket: 'bossfinal-581aa.appspot.com',
  );
}
