// This file is generated from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist.
// Project: apps2-752cb（yourwishモノレポ命名規則）
//
// ⚠️ STALE: android/app/build.gradle.ktsとios/Runner.xcodeproj/project.pbxprojの
// applicationId/bundle IDはcom.yourwish.cardrivalsへ変更済みだが、このファイルは
// 旧パッケージ名(com.yourwish.cardcrown)で登録した時点のFirebaseプロジェクト情報の
// ままになっている。新しいFirebaseプロジェクトでcom.yourwish.cardrivalsとして
// Android/iOSアプリを登録した後、`flutterfire configure` を再実行してこのファイルを
// 再生成すること。
// （手動で書き換える場合は android/app/google-services.json と
//  ios/Runner/GoogleService-Info.plist の値をそのまま転記する）

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqvvJcP4lPYv811PNvs1TptSIhtHupjFY',
    appId: '1:946448575860:android:6b1a566317080ad637d021',
    messagingSenderId: '946448575860',
    projectId: 'apps2-752cb',
    storageBucket: 'apps2-752cb.firebasestorage.app',
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
