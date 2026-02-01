import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notifications = fln.FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      
      // Android settings
      const androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS settings
      const iosSettings = fln.DarwinInitializationSettings(
        requestAlertPermission: false, // Don't request yet
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _notifications.initialize(
        settings: const fln.InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      // Create channel explicitly
      const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
        'medication_channel_v3', 
        'Medication Reminders', 
        description: 'Reminders to take your medications', 
        importance: fln.Importance.max,
      );
      
      await _notifications
          .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('NotificationService initialized (Timezone: $timeZoneName)');
    } catch (e, s) {
      debugPrint('Notification init failed: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> requestPermissions() async {
    try {
      // Android 13+ Notifications
      final bool? granted = await _notifications
          .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      debugPrint('Notification Permission Granted: $granted');

      // Android 12+ Exact Alarms
      // Note: This might open a system setting if not granted
      await _notifications
          .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
          
      // iOS
      await _notifications
          .resolvePlatformSpecificImplementation<fln.IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  // NEW: Reliable One-Shot Scheduling
  // Instead of complex repeating rules, we schedule ONLY the next specific instance.
  Future<void> scheduleOneShotAlarm(String medId, String title, String body, DateTime scheduledDate) async {
    try {
      final notificationId = medId.hashCode; // Unique ID per medication
      debugPrint('Scheduling ONE-SHOT for $medId at $scheduledDate');

      await _notifications.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'medication_channel_v3',
            'Medication Reminders',
            channelDescription: 'Reminders to take your medications',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null, // ONE-TIME only
      );
      debugPrint('Success: One-shot scheduled for $scheduledDate');
    } catch (e, s) {
      debugPrint('Error scheduling one-shot: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id: id); // Fixed: Added named parameter 'id'
      debugPrint('Cancelled notification ID: $id');
    } catch (e) {
      debugPrint('Error canceling notification $id: $e');
    }
  }

  Future<void> showTestNotification() async {
    const androidDetails = fln.AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Initial instant notification
    await _notifications.show(
      id: 888, 
      title: 'Test Notification',
      body: 'Notifications are working! Expect a delayed one in 10s.',
      notificationDetails: details,
    );

    // EXACT Schedule (10s)
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      await _notifications.zonedSchedule(
        id: 999,
        title: 'Delayed Test (EXACT)',
        body: 'If you see this, EXACT alarms work.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Scheduled EXACT test notification for 10s from now');
    } catch (e) {
      debugPrint('FAILED to schedule EXACT test: $e');
    }
  }

  Future<void> getPendingNotificationCount() async {
    final List<fln.PendingNotificationRequest> pending = 
        await _notifications.pendingNotificationRequests();
    debugPrint('PENDING NOTIFICATIONS: ${pending.length}');
    for (var p in pending) {
      debugPrint(' - ID: ${p.id}, Title: ${p.title} @ ${p.payload}');
    }
  }

  Future<void> cancelReminders(String medId, List<String> doseTimes) async {
     for (var slot in doseTimes) {
        final id = "${medId}_$slot".hashCode;
        await _notifications.cancel(id: id);
     }
  }
  
  Future<void> cancelAll() => _notifications.cancelAll();
}
