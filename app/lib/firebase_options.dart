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
        return windows;
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
    apiKey: 'AIzaSyBbt2T8IqRd6XfFJZJewK_B8u1NPwUk3Fo',
    appId: '1:429075151762:web:a4f1349417e9558a02df4b',
    messagingSenderId: '429075151762',
    projectId: 'kajimbola-budgetflow',
    authDomain: 'kajimbola-budgetflow.firebaseapp.com',
    storageBucket: 'kajimbola-budgetflow.firebasestorage.app',
    measurementId: 'G-WKYN2KT1TP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCFWxHYl5UxkJpJo1RuOBs3yAr_gzaSUzw',
    appId: '1:429075151762:android:180e368965e5834e02df4b',
    messagingSenderId: '429075151762',
    projectId: 'kajimbola-budgetflow',
    storageBucket: 'kajimbola-budgetflow.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyACXtIYVroIDL09yomC85upGCbmWh6e7MY',
    appId: '1:429075151762:ios:f94da32bfc7607db02df4b',
    messagingSenderId: '429075151762',
    projectId: 'kajimbola-budgetflow',
    storageBucket: 'kajimbola-budgetflow.firebasestorage.app',
    iosBundleId: 'com.example.ouverture',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyACXtIYVroIDL09yomC85upGCbmWh6e7MY',
    appId: '1:429075151762:ios:f94da32bfc7607db02df4b',
    messagingSenderId: '429075151762',
    projectId: 'kajimbola-budgetflow',
    storageBucket: 'kajimbola-budgetflow.firebasestorage.app',
    iosBundleId: 'com.example.ouverture',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBbt2T8IqRd6XfFJZJewK_B8u1NPwUk3Fo',
    appId: '1:429075151762:web:b8cb3d9edbb5432102df4b',
    messagingSenderId: '429075151762',
    projectId: 'kajimbola-budgetflow',
    authDomain: 'kajimbola-budgetflow.firebaseapp.com',
    storageBucket: 'kajimbola-budgetflow.firebasestorage.app',
    measurementId: 'G-VSWWBCP9P5',
  );

}