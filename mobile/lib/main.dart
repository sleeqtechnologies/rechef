import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'app/subscription/data/subscription_repository.dart';
import 'core/config/env.dart';
import 'core/services/cooking_timer_notifications.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  prefs.remove('onboarding_complete');

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await CookingTimerNotifications.instance.initialize();

  final repo = SubscriptionRepository(apiKey: revenueCatApiKey);
  final currentUser = FirebaseAuth.instance.currentUser;
  await repo.configure(appUserId: currentUser?.uid);

  runApp(const ProviderScope(child: RechefApp()));
}
