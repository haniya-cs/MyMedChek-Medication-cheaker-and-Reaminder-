import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'medication.dart';
import 'recurrence.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static const int _baseIdMultiplier = 10000;
  static const int _everyXDaysBaseId = 90000000;
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    tz.initializeTimeZones();
    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'med_channel',
        'Medication Reminders',
        channelDescription: 'Channel for scheduled medicine intake reminders.',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  static int generateNotificationId(
      int medicineId, int timeSlotIndex, {int dayOfWeek = 0}) {
    return (medicineId * _baseIdMultiplier) + (timeSlotIndex * 10) + dayOfWeek;
  }
  static int generateAlarmId(int medicineId, int timeSlotIndex) {
    return _everyXDaysBaseId + (medicineId * 10) + timeSlotIndex;
  }

  static Future<void> scheduleMedicine({required Medicine medicine}) async {
    await cancelAllReminders(medicine.id);
    switch (medicine.recurrence) {
      case RecurrenceType.daily:
        await _scheduleDaily(medicine);
        break;

      case RecurrenceType.dayOfWeek:
        if (medicine.daysOfWeek != null) {
          await _scheduleWeekly(medicine);
        }
        break;

      case RecurrenceType.once:
        await _scheduleOneTime(medicine);
        break;

      case RecurrenceType.everyXDays:
        await _scheduleEveryXDays(medicine);
        break;

      case RecurrenceType.monthly:
        await _scheduleMonthly(medicine);
        break;
    }
  }

  static Future<void> _scheduleMonthly(Medicine medicine) async {
    final int? targetDayOfMonth = medicine.dayOfMonth;
    if (targetDayOfMonth == null || targetDayOfMonth < 1 || targetDayOfMonth > 31) return;

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        targetDayOfMonth,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month + 1,
          targetDayOfMonth,
          time.hour,
          time.minute,
        );
      }

      await _notifications.zonedSchedule(
        generateNotificationId(medicine.id, i),
        'Time for ${medicine.name}',
        'Take your ${medicine.dose} dose now.',
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
  static Future<void> _scheduleDaily(Medicine medicine) async {
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];

      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, time.hour, time.minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        generateNotificationId(medicine.id, i),
        'Time for ${medicine.name}',
        'Take your ${medicine.dose} dose now.',
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
  static Future<void> _scheduleWeekly(Medicine medicine) async {
    final List<int> daysOfWeek = medicine.daysOfWeek!;
    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];
      for (var day in daysOfWeek) {
        final scheduledDate = _nextInstanceOfWeekday(day, time);
        final id = generateNotificationId(medicine.id, i, dayOfWeek: day);
        await _notifications.zonedSchedule(
          id,
          'Time for ${medicine.name}',
          'Take your ${medicine.dose} dose now.',
          scheduledDate,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static Future<void> _scheduleOneTime(Medicine medicine) async {
    final DateTime? targetDate = medicine.targetDate;
    if (targetDate == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final tzTargetDate = tz.TZDateTime.from(targetDate, tz.local);

    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];
      var scheduledDate = tz.TZDateTime(
          tz.local,
          tzTargetDate.year,
          tzTargetDate.month,
          tzTargetDate.day,
          time.hour,
          time.minute
      );
      if (scheduledDate.isBefore(now)) {
        continue;
      }

      await _notifications.zonedSchedule(
        generateNotificationId(medicine.id, i),
        'Time for ${medicine.name}',
        'Take your ${medicine.dose} dose now.',
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> _scheduleEveryXDays(Medicine medicine) async {
    final DateTime? targetDate = medicine.targetDate;
    final int? everyXDays = medicine.everyXDays;

    if (targetDate == null || everyXDays == null || everyXDays < 1) return;
    final tzTargetDate = tz.TZDateTime.from(targetDate, tz.local);
    final Duration interval = Duration(days: everyXDays);
    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];
      generateAlarmId(medicine.id, i);
      var firstScheduledDate = tz.TZDateTime(
          tz.local,
          tzTargetDate.year,
          tzTargetDate.month,
          tzTargetDate.day,
          time.hour,
          time.minute
      );
      while (firstScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        firstScheduledDate = firstScheduledDate.add(interval);
      }
      await _notifications.zonedSchedule(
        generateNotificationId(medicine.id, i),
        'Time for ${medicine.name}',
        'Take your ${medicine.dose} dose now.',
        firstScheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

    }
  }
  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
  static Future<void> cancelAllReminders(int medicineId) async {
    for (int timeIndex = 0; timeIndex < 10; timeIndex++) {
      for (int day = 0; day <= 7; day++) {
        final idToCancel = generateNotificationId(medicineId, timeIndex, dayOfWeek: day);
        await _notifications.cancel(idToCancel);
      }
      generateAlarmId(medicineId, timeIndex);
    }
  }
}