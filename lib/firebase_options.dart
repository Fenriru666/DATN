// File generated manually based on user provided config.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDx3eSGhxPHT8apP46AL6QGZtpxhLH97aw',
    appId: '1:231708624859:web:0415b13f3d90229d8b09fe',
    messagingSenderId: '231708624859',
    projectId: 'datn-3daa6',
    authDomain: 'datn-3daa6.firebaseapp.com',
    storageBucket: 'datn-3daa6.firebasestorage.app',
    measurementId: 'G-WL0TDVC9VB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBC1vOvmlIhpuU-1J3EMezcoHGKNfK-SV0',
    appId: '1:231708624859:android:42f206254f7212898b09fe',
    messagingSenderId: '231708624859',
    projectId: 'datn-3daa6',
    storageBucket: 'datn-3daa6.firebasestorage.app',
  );
}
