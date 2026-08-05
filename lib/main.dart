import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/bonus_detail_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/home_screen_v2.dart';
import 'screens/purchase_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'services/purchase_service.dart';
import 'theme/kingdom_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await PurchaseService.init();
  } catch (e) {
    // RevenueCat未設定（APIキー未発行）でも課金以外の機能は使えるようにアプリを止めない
    debugPrint('PurchaseService init failed: $e');
  }
  runApp(
    const ProviderScope(
      child: CardCrownApp(),
    ),
  );
}

class CardCrownApp extends ConsumerWidget {
  const CardCrownApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Card Crown',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: Kingdom.materialTheme(),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreenV2(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: '/bonus-detail',
      builder: (context, state) => const BonusDetailScreen(),
    ),
    GoRoute(
      path: '/purchase-history',
      builder: (context, state) => const PurchaseHistoryScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactScreen(),
    ),
  ],
);
