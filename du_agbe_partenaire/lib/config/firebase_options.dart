import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
    apiKey: 'VOTRE_API_KEY_ANDROID',
    appId: 'VOTRE_APP_ID_ANDROID',
    messagingSenderId: 'VOTRE_MESSAGING_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'VOTRE_API_KEY_IOS',
    appId: 'VOTRE_APP_ID_IOS',
    messagingSenderId: 'VOTRE_MESSAGING_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_STORAGE_BUCKET',
  );
}