import 'package:flutter/material.dart';
import 'recurrence.dart';
class Medicine {
  final int id;
  final String name;
  final String dose;
  final RecurrenceType recurrence;
  final List<TimeOfDay> times;
  final List<int>? daysOfWeek;
  final int? intervalDays;
  final int? dayOfMonth;
  final DateTime? targetDate;
  final int? everyXDays;
  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.recurrence,
    required this.times,
    this.daysOfWeek,
    this.intervalDays,
    this.dayOfMonth,
    this.targetDate,
    this.everyXDays,
  });
}