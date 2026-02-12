import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules local notifications to remind the user to cook a recipe at a
/// chosen date/time. Reminders are persisted via [SharedPreferences] so the
/// UI can display / clear them.
class CookReminderNotifications {
  CookReminderNotifications._();

  static final CookReminderNotifications instance =
      CookReminderNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'cook_reminder';
  static const String _channelName = 'Cook Reminders';
  static const String _prefsPrefix = 'cook_reminder_';

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

  /// Derives a stable, positive notification ID from [recipeId] that won't
  /// collide with cooking-timer (1) or recipe-ready (1000–1999) IDs.
  int _notificationId(String recipeId) =>
      (recipeId.hashCode & 0x7FFFFFFF) | 0x40000000;

  /// Schedule a reminder for [recipeName] at [dateTime].
  Future<void> schedule(
    String recipeId,
    String recipeName,
    DateTime dateTime,
  ) async {
    await _ensureInitialized();

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

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

    await _plugin.zonedSchedule(
      id: _notificationId(recipeId),
      title: 'notifications.time_to_cook'.tr(),
      body: recipeName,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Persist so the UI can check if a reminder exists.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsPrefix$recipeId',
      dateTime.toIso8601String(),
    );
  }

  /// Cancel an existing reminder for [recipeId].
  Future<void> cancel(String recipeId) async {
    await _plugin.cancel(id: _notificationId(recipeId));

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix$recipeId');
  }

  /// Returns the scheduled reminder [DateTime] for [recipeId], or `null` if
  /// none is set (or if it's in the past).
  Future<DateTime?> getReminder(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix$recipeId');
    if (raw == null) return null;

    final dt = DateTime.tryParse(raw);
    if (dt == null || dt.isBefore(DateTime.now())) {
      // Clean up stale entry.
      await prefs.remove('$_prefsPrefix$recipeId');
      return null;
    }
    return dt;
  }
}
