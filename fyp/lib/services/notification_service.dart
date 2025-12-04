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

  /// Schedules 3 notifications (Food, Weight, Water) to repeat every 12 hours.
  /// Example: 10:00 AM and 10:00 PM
  /// Gap: 1 minute between each category.
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

    // Schedule for 10:00 AM and 10:00 PM (22:00)
    // This creates a 12-hour cycle.
    for (int i = 0; i < 2; i++) {
      int hour = 10 + (i * 12); // i=0 -> 10, i=1 -> 22
      
      // Calculate the next occurrence of this hour
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0, // Start at :00 minutes
      );

      // If the time has already passed for today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Unique IDs: Morning (100s), Evening (200s)
      int baseId = (i + 1) * 100;

      // 1. Food Reminder (Hour:00)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 1,
        '🍎 NutriWise Daily',
        'Don\'t forget to log your meals!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at this time
        payload: 'food_log',
      );

      // 2. Weight Reminder (Hour:01) - 1 min gap
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 2,
        '⚖️ Track Your Progress',
        'Please log your weight to keep your stats updated.',
        scheduledDate.add(const Duration(minutes: 1)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'weight_log',
      );

      // 3. Water Reminder (Hour:02) - 1 min gap
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 3,
        '💧 Stay Hydrated',
        'Final check: Have you logged your water intake?',
        scheduledDate.add(const Duration(minutes: 2)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'water_log',
      );
    }

    debugPrint("📅 NutriWise: Reminders scheduled for 10:00 AM & 10:00 PM.");
  }
}