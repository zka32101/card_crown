// This file is generated from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist.
// Account: funvestment1@gmail.com / Android Project: app1-6c108
// Android Package ID: com.yourwish.cardrivals
//
// ⚠️ iOS側は未修正: iosBundleIdはcom.yourwish.cardrivalsへ変更済みだが、
// iOS用のFirebaseプロジェクト登録（apps2-752cb）はまだ旧パッケージ名
// (com.yourwish.cardcrown)時点のままの可能性がある。iOSビルド前に
// Firebase Consoleでcom.yourwish.cardrivalsとしてiOSアプリを登録し、
// `flutterfire configure`でiosセクションを再生成すること。

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDz8Kg7hwRbh34FbKCguiLQe0oJDkPP62Y',
    appId: '1:663640153690:android:c0f711e3418af3debe4263',
    messagingSenderId: '663640153690',
    projectId: 'app1-6c108',
    storageBucket: 'app1-6c108.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4gaFcLxN8iT7xm6JeIM7Iou-efE5g5SM',
    appId: '1:946448575860:ios:ed03d105e51b383e37d021',
    messagingSenderId: '946448575860',
    projectId: 'apps2-752cb',
    storageBucket: 'apps2-752cb.firebasestorage.app',
    iosBundleId: 'com.yourwish.cardcrown',
  );

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }
}
