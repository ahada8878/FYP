import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    // Optional: Hardcode to Pakistan for testing if device time fails
    // try { tz.setLocalLocation(tz.getLocation('Asia/Karachi')); } catch (e) {}

    // 2. Config Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap here (e.g., navigate to Food Log screen)
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  /// Schedules notifications every 5 minutes with a 1-minute gap:
  /// Cycle 1 (Starts +5 min): Food @ T+5, Weight @ T+6, Water @ T+7
  /// Cycle 2 (Starts +10 min): Food @ T+10, Weight @ T+11, Water @ T+12
  /// ...Repeats for a set number of cycles (e.g., 1 hour)
  Future<void> scheduleDailyReminders() async {
    // Cancel old ones to avoid duplicates
    await flutterLocalNotificationsPlugin.cancelAll();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'nutriwise_daily_channel',
      'Daily Reminders',
      channelDescription: 'Reminders to log food, weight, and water',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);

    // Schedule for the next 60 minutes (12 cycles of 5 minutes)
    // You can increase the loop count for longer duration
    for (int i = 0; i < 12; i++) {
      // Every 5 minutes: 5, 10, 15...
      int baseDelayMinutes = (i + 1) * 5;
      
      // Unique IDs for each instance
      // Cycle 0: 100, 101, 102
      // Cycle 1: 200, 201, 202
      int baseId = (i * 100) + 100;

      // 1. Food Reminder (Base time)
      // e.g., i=0 -> T+5 min
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 1,
        '🍎 NutriWise Daily',
        'Don\'t forget to log your meals for today!',
        now.add(Duration(minutes: baseDelayMinutes)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'food_log',
      );

      // 2. Weight Reminder (Base + 1 minute gap)
      // e.g., i=0 -> T+6 min
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 2,
        '⚖️ Track Your Progress',
        'Please log your weight to keep your stats updated.',
        now.add(Duration(minutes: baseDelayMinutes + 1)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'weight_log',
      );

      // 3. Water Reminder (Base + 2 minute gap)
      // e.g., i=0 -> T+7 min
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 3,
        '💧 Stay Hydrated',
        'Final check: Have you logged your water intake?',
        now.add(Duration(minutes: baseDelayMinutes + 2)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'water_log',
      );
    }

    debugPrint("📅 NutriWise: Reminders scheduled every 5 minutes for the next hour.");
  }
}