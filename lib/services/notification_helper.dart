import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugin
  static Future<void> initialize() async {
    // Delete the existing notification channel to apply new settings
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('alarm_channel');

    // Create a new notification channel with updated settings
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarms',
      description: 'Notification channel for alarms',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );

    // Initialize the notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize the notification plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Initializes timezone data for local notifications
  static Future<void> initializeTimezones() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation('America/Los_Angeles')); // Default fallback

    try {
      final localTimeZone = tz.local.name; // Gets the current local timezone
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (e) {
      print("Error setting the local timezone: $e");
      // Fallback to a default timezone if something goes wrong
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Schedules a notification with a specified title, body, and scheduled time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Notification channel for alarms',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(
          scheduledTime, tz.local), // Convert DateTime to TZDateTime
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  /// Cancels a specific notification by ID
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancels all notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
