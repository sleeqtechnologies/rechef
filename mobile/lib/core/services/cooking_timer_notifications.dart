import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Schedules local notifications when cooking timers complete.
/// Supports iOS (priority) and Android.
class CookingTimerNotifications {
  CookingTimerNotifications._();

  static final CookingTimerNotifications instance = CookingTimerNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _timerNotificationId = 1;
  static const String _channelId = 'cooking_timer';
  static const String _channelName = 'Cooking Timer';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(settings: initSettings);

    if (!kIsWeb && Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        sound: true,
        badge: false,
      );
    }

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    if (!kIsWeb && Platform.isAndroid) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    if (!kIsWeb) {
      try {
        tz_data.initializeTimeZones();
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (_) {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    _initialized = true;
  }

  Future<void> scheduleTimerDone(int seconds, String label) async {
    if (!_initialized) await initialize();

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

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
      id: _timerNotificationId,
      title: 'Timer done',
      body: 'Timer done: $label',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTimerDone() async {
    await _plugin.cancel(id: _timerNotificationId);
  }
}
