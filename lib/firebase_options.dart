import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSNZbS2BC6cv4r3vLRfgbpfZ4JqeDMyGI',
    appId: '1:785077070579:web:3ac9482ffcfdfc84362586',
    messagingSenderId: '785077070579',
    projectId: 'servisku-172b7',
    authDomain: 'servisku-172b7.firebaseapp.com',
    storageBucket: 'servisku-172b7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAv2EQQ_qgees6th4LtV2o1t4S9n97v6Xc',
    appId: '1:785077070579:android:38f838a4d4ed90e4362586',
    messagingSenderId: '785077070579',
    projectId: 'servisku-172b7',
    storageBucket: 'servisku-172b7.firebasestorage.app',
  );
}
