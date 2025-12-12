import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'medication.dart';
import 'recurrence.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
  GlobalKey<ScaffoldMessengerState>();

  // Stores running timers
  static final AudioPlayer _player = AudioPlayer();
  static final Map<int, Timer> _timers = {};

  static void init() {}

  // Shows snackbar from anywhere
  static void _showSnackbar(String title, String body)async {
    await _player.play(AssetSource('alert.mp3'));
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text("$title\n$body"),
        duration: const Duration(seconds: 20),
      ),
    );
  }

  // Generates unique ID for each timer
  static int generateId(int medicineId, int slot, {int day = 0}) {
    return medicineId * 100000 + slot * 100 + day;
  }

  // Main scheduler for a single time slot
  static void _scheduleNextTimer({
    required int id,
    required Medicine medicine,
    required TimeOfDay time,
    int? weekday,
    DateTime? after,
  }) {
    DateTime? next = _computeNext(
      medicine: medicine,
      time: time,
      weekday: weekday,
      after: after,
    );

    if (next == null) return;

    Duration delay = next.difference(DateTime.now());
    if (delay.isNegative) return;

    // Cancel previous timer
    _timers[id]?.cancel();

    // Schedule new timer
    _timers[id] = Timer(delay, () {
      _showSnackbar(
        " It's Time for ${medicine.name} Medicine",
        "Take your ${medicine.dose} now.",
      );

      // Do not reschedule "once"
      if (medicine.recurrence == RecurrenceType.once) {
        _timers.remove(id);
        return;
      }

      // Reschedule next occurrence
      _scheduleNextTimer(
        id: id,
        medicine: medicine,
        time: time,
        weekday: weekday,
        after: next.add(const Duration(seconds: 1)),
      );
    });
  }

  // Computes next time the reminder should fire
  static DateTime? _computeNext({
    required Medicine medicine,
    required TimeOfDay time,
    int? weekday,
    DateTime? after,
  }) {
    final now = DateTime.now();
    final start = after ?? now;

    DateTime candidate;

    switch (medicine.recurrence) {
      case RecurrenceType.once:
        if (medicine.targetDate == null) return null;
        candidate = DateTime(
          medicine.targetDate!.year,
          medicine.targetDate!.month,
          medicine.targetDate!.day,
          time.hour,
          time.minute,
        );
        return candidate.isAfter(start) ? candidate : null;

      case RecurrenceType.daily:
        candidate = DateTime(
          start.year,
          start.month,
          start.day,
          time.hour,
          time.minute,
        );
        if (!candidate.isAfter(start)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case RecurrenceType.dayOfWeek:
        if (weekday == null) return null;

        candidate = DateTime(
          start.year,
          start.month,
          start.day,
          time.hour,
          time.minute,
        );

        int safety = 0;
        while ((candidate.weekday != weekday || !candidate.isAfter(start)) &&
            safety < 14) {
          candidate = candidate.add(const Duration(days: 1));
          safety++;
        }
        return candidate.isAfter(start) ? candidate : null;

      case RecurrenceType.everyXDays:
        if (medicine.targetDate == null || (medicine.everyXDays ?? 0) < 1) {
          return null;
        }

        final every = medicine.everyXDays!;
        DateTime first = DateTime(
          medicine.targetDate!.year,
          medicine.targetDate!.month,
          medicine.targetDate!.day,
          time.hour,
          time.minute,
        );

        if (first.isAfter(start)) return first;

        final daysDiff = start.difference(first).inDays;
        final cycles = (daysDiff ~/ every) + 1;
        candidate = first.add(Duration(days: cycles * every));
        return candidate.isAfter(start) ? candidate : null;

      case RecurrenceType.monthly:
        if (medicine.dayOfMonth == null) return null;

        int targetDay = medicine.dayOfMonth!;
        int year = start.year;
        int month = start.month;

        candidate = DateTime(year, month, targetDay, time.hour, time.minute);

        if (!candidate.isAfter(start)) {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
          candidate = DateTime(year, month, targetDay, time.hour, time.minute);
        }

        // Day does not exist (e.g., Feb 30)
        if (candidate.day != targetDay) return null;

        return candidate;
    }
  }

  // Schedules all reminders for a medicine
  static void scheduleMedicine(Medicine medicine) {
    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];

      switch (medicine.recurrence) {
        case RecurrenceType.daily:
        case RecurrenceType.once:
        case RecurrenceType.everyXDays:
        case RecurrenceType.monthly:
          final id = generateId(medicine.id, i);
          _scheduleNextTimer(id: id, medicine: medicine, time: time);
          break;

        case RecurrenceType.dayOfWeek:
          for (int weekday in medicine.daysOfWeek ?? []) {
            final id = generateId(medicine.id, i, day: weekday);
            _scheduleNextTimer(
              id: id,
              medicine: medicine,
              time: time,
              weekday: weekday,
            );
          }
          break;
      }
    }
  }
}
