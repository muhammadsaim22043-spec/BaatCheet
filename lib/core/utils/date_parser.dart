// lib/core/utils/date_parser.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DateParser {
  /// Reads a date stored in Firestore as either an ISO-8601 string or a
  /// Firestore Timestamp and returns it in the device's local time zone.
  static DateTime fromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  /// Always write UTC so devices in different time zones sort and display
  /// messages consistently.
  static String toFirestore(DateTime value) => value.toUtc().toIso8601String();
}
