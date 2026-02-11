import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app/onboarding/data/onboarding_repository.dart';
import 'app/subscription/data/subscription_repository.dart';
import 'core/config/env.dart';
import 'core/services/cooking_timer_notifications.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await CookingTimerNotifications.instance.initialize();

  final repo = SubscriptionRepository(apiKey: revenueCatApiKey);
  final currentUser = FirebaseAuth.instance.currentUser;
  await repo.configure(appUserId: currentUser?.uid);

  // Pre-load onboarding status so the router has it immediately.
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        // Seed with the pre-loaded value so the router doesn't flash.
        onboardingCompleteProvider.overrideWith((_) => onboardingDone),
      ],
      child: const RechefApp(),
    ),
  );
}
