import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'app.dart';
import 'app/subscription/data/subscription_repository.dart';
import 'core/config/env.dart';
import 'core/services/cooking_timer_notifications.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  await CookingTimerNotifications.instance.initialize();

  final posthogConfig = PostHogConfig(posthogApiKey)
    ..host = 'https://us.i.posthog.com'
    ..sessionReplay = true
    ..sessionReplayConfig.maskAllImages = false
    ..sessionReplayConfig.maskAllTexts = true;
  await Posthog().setup(posthogConfig);

  final repo = SubscriptionRepository(apiKey: revenueCatApiKey);
  final currentUser = FirebaseAuth.instance.currentUser;
  await repo.configure(appUserId: currentUser?.uid);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
        Locale('de'),
        Locale('pt'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: RechefApp()),
    ),
  );
}
