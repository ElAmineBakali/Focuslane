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
    apiKey: 'AIzaSyDFJpnAHQUYuTnePvpJeLzKrFnHxYMques',
    appId: '1:685961389524:web:9ff5b7a0e2bc5ddf98a241',
    messagingSenderId: '685961389524',
    projectId: 'maestro-592cd',
    authDomain: 'maestro-592cd.firebaseapp.com',
    storageBucket: 'maestro-592cd.firebasestorage.app',
    measurementId: 'G-R1SV0E4MBP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOsgKP0fPwY2WZTa7Kck_QSEzwun1QBFs',
    appId: '1:685961389524:android:2292189ea121358a98a241',
    messagingSenderId: '685961389524',
    projectId: 'maestro-592cd',
    storageBucket: 'maestro-592cd.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDFJpnAHQUYuTnePvpJeLzKrFnHxYMques',
    appId: '1:685961389524:web:17f676b23fe64dc298a241',
    messagingSenderId: '685961389524',
    projectId: 'maestro-592cd',
    authDomain: 'maestro-592cd.firebaseapp.com',
    storageBucket: 'maestro-592cd.firebasestorage.app',
    measurementId: 'G-T19KCG5RVW',
  );
}