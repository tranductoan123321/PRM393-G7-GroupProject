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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForDevTesting123456789',
    appId: '1:1234567890:web:abcdef123456789',
    messagingSenderId: '1234567890',
    projectId: 'efashion-flutter-dev',
    authDomain: 'efashion-flutter-dev.firebaseapp.com',
    storageBucket: 'efashion-flutter-dev.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdg5TuWK2I5fS9SBV2AzrPqEcMA1fEE-o',
    appId: '1:814785327165:android:b14594c32f35228301fa54',
    messagingSenderId: '814785327165',
    projectId: 'efashion-mobile',
    storageBucket: 'efashion-mobile.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCdg5TuWK2I5fS9SBV2AzrPqEcMA1fEE-o',
    appId: '1:814785327165:android:b14594c32f35228301fa54',
    messagingSenderId: '814785327165',
    projectId: 'efashion-mobile',
    storageBucket: 'efashion-mobile.firebasestorage.app',
    iosBundleId: 'com.bitio.efashion_flutter',
  );
}
