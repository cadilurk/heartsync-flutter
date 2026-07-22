// File generated for Firebase options configuration.
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
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDmJrtYzSp3DZ0UadzIGenU1Lg691FrJk4',
    appId: '1:236247833644:web:64a5b180d4e8f7fcb84589',
    messagingSenderId: '236247833644',
    projectId: 'heartsync-fa971',
    authDomain: 'heartsync-fa971.firebaseapp.com',
    storageBucket: 'heartsync-fa971.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmJrtYzSp3DZ0UadzIGenU1Lg691FrJk4',
    appId: '1:236247833644:android:64a5b180d4e8f7fcb84589',
    messagingSenderId: '236247833644',
    projectId: 'heartsync-fa971',
    storageBucket: 'heartsync-fa971.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmJrtYzSp3DZ0UadzIGenU1Lg691FrJk4',
    appId: '1:236247833644:ios:64a5b180d4e8f7fcb84589',
    messagingSenderId: '236247833644',
    projectId: 'heartsync-fa971',
    storageBucket: 'heartsync-fa971.firebasestorage.app',
    iosBundleId: 'com.example.heartsync_flutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDmJrtYzSp3DZ0UadzIGenU1Lg691FrJk4',
    appId: '1:236247833644:ios:64a5b180d4e8f7fcb84589',
    messagingSenderId: '236247833644',
    projectId: 'heartsync-fa971',
    storageBucket: 'heartsync-fa971.firebasestorage.app',
    iosBundleId: 'com.example.heartsync_flutter',
  );
}
