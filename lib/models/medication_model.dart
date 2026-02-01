import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String? id;
  final String userId;
  final String name;
  final String? dosage; // Optional
  final String frequency; // '1x', '2x', '3x', 'PRN'
  final List<String> doseTimes; // ['08:00', '20:00']
  final String timeMode; // 'simple', 'advanced'
  final DateTime startDate;
  final DateTime? endDate; // Derived from duration
  final String intakeRule; // 'before_food', 'after_food', 'empty_stomach', 'none'
  final Map<String, dynamic> takenLog; // {'2023-10-27': ['08:00']}
  final DateTime createdAt;
  final DateTime? nextDoseAt; // NEW: Tracks the exact next scheduled dose

  Medication({
    this.id,
    required this.userId,
    required this.name,
    this.dosage,
    required this.frequency,
    required this.doseTimes,
    this.timeMode = 'simple',
    required this.startDate,
    this.endDate,
    required this.intakeRule,
    this.takenLog = const {},
    required this.createdAt,
    this.nextDoseAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'doseTimes': doseTimes,
      'timeMode': timeMode,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'intakeRule': intakeRule,
      'takenLog': takenLog,
      'createdAt': Timestamp.fromDate(createdAt),
      'nextDoseAt': nextDoseAt != null ? Timestamp.fromDate(nextDoseAt!) : null,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map, String id) {
    // Migration logic for old 'timeSlots'
    List<String> times = [];
    if (map['doseTimes'] != null) {
      times = List<String>.from(map['doseTimes']);
    } else if (map['timeSlots'] != null) {
      final oldSlots = List<String>.from(map['timeSlots']);
      for (var slot in oldSlots) {
        if (slot == 'Morning') times.add('08:00');
        else if (slot == 'Afternoon') times.add('14:00');
        else if (slot == 'Evening') times.add('20:00');
      }
    }

    return Medication(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'],
      frequency: map['frequency'] ?? '1x',
      doseTimes: times,
      timeMode: map['timeMode'] ?? 'simple',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      intakeRule: map['intakeRule'] ?? 'none',
      takenLog: Map<String, dynamic>.from(map['takenLog'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextDoseAt: (map['nextDoseAt'] as Timestamp?)?.toDate(),
    );
  }

  // Helper to check if taken for a specific date and slot
  bool isTaken(DateTime date, String slot) {
    if (frequency == 'PRN') return false; 
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final takenSlots = List<String>.from(takenLog[dateKey] ?? []);
    return takenSlots.contains(slot);
  }

  // Helper to check if medication is active on a specific date
  bool isActiveOn(DateTime date) {
     // Check if date is before start date (ignore time)
     final justDate = DateTime(date.year, date.month, date.day);
     final start = DateTime(startDate.year, startDate.month, startDate.day);
     if (justDate.isBefore(start)) return false;

     // Check if date is after end date
     if (endDate != null) {
        final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
        if (justDate.isAfter(end)) return false;
     }
     
     return true;
  }
}
