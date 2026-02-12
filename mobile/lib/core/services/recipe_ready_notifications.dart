import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows a local notification when a recipe import job finishes.
class RecipeReadyNotifications {
  RecipeReadyNotifications._();

  static final RecipeReadyNotifications instance =
      RecipeReadyNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'recipe_ready';
  static const String _channelName = 'Recipe Import';

  /// Counter so each notification gets a unique ID (starts at 1000 to avoid
  /// colliding with the cooking-timer notification ID of 1).
  int _nextId = 1000;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await androidPlugin?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Show an immediate "Recipe Ready" notification.
  Future<void> show() async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _nextId++,
      title: 'notifications.recipe_ready'.tr(),
      body: 'notifications.recipe_generated'.tr(),
      notificationDetails: details,
    );
  }
}
