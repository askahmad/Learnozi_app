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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAvLU2KYuoom-PWzfa13zV_pkEizfWdr_s',
    appId: '1:1093846130452:web:learnozi',
    messagingSenderId: '1093846130452',
    projectId: 'learnozi',
    authDomain: 'learnozi.firebaseapp.com',
    storageBucket: 'learnozi.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvLU2KYuoom-PWzfa13zV_pkEizfWdr_s',
    appId: '1:1093846130452:android:85e1e3a2e8d6796d386c01',
    messagingSenderId: '1093846130452',
    projectId: 'learnozi',
    storageBucket: 'learnozi.firebasestorage.app',
  );
}
