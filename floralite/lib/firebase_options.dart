// File generated for Floraprise project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDJJTa6I2ku2otW_2hyCJ3TXhVSvoEQuyg',
    appId: '1:795467295347:web:c47d8e22382aba5b635806',
    messagingSenderId: '795467295347',
    projectId: 'floraprise-b3dd5',
    authDomain: 'floraprise-b3dd5.firebaseapp.com',
    storageBucket: 'floraprise-b3dd5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJJTa6I2ku2otW_2hyCJ3TXhVSvoEQuyg',
    appId: '1:795467295347:android:c47d8e22382aba5b635806',
    messagingSenderId: '795467295347',
    projectId: 'floraprise-b3dd5',
    storageBucket: 'floraprise-b3dd5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJJTa6I2ku2otW_2hyCJ3TXhVSvoEQuyg',
    appId: '1:795467295347:ios:c47d8e22382aba5b635806',
    messagingSenderId: '795467295347',
    projectId: 'floraprise-b3dd5',
    storageBucket: 'floraprise-b3dd5.firebasestorage.app',
    iosBundleId: 'com.floraprise.app',
  );
}
