import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String? id;
  final String userId;
  final String name;
  final String? dosage; // Optional now
  final String frequency; // '1x', '2x', '3x', 'PRN'
  final List<String> timeSlots; // ['Morning', 'Evening'] or ['08:00', '20:00']
  final String timeMode; // 'simple', 'advanced'
  final DateTime startDate; 
  final String intakeRule; // 'before_food', 'after_food', 'empty_stomach', 'none'
  final bool isActive;
  final Map<String, dynamic> takenLog; // {'2023-10-27': ['Morning']}
  final DateTime createdAt;

  Medication({
    this.id,
    required this.userId,
    required this.name,
    this.dosage,
    required this.frequency,
    required this.timeSlots,
    this.timeMode = 'simple',
    required this.startDate,
    required this.intakeRule,
    this.isActive = true,
    this.takenLog = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeSlots': timeSlots,
      'timeMode': timeMode,
      'startDate': Timestamp.fromDate(startDate),
      'intakeRule': intakeRule,
      'isActive': isActive,
      'takenLog': takenLog,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map, String id) {
    return Medication(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'],
      frequency: map['frequency'] ?? '1x',
      timeSlots: List<String>.from(map['timeSlots'] ?? []),
      timeMode: map['timeMode'] ?? 'simple',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(), // Fallback for old data
      intakeRule: map['intakeRule'] ?? 'none',
      isActive: map['isActive'] ?? true,
      takenLog: Map<String, dynamic>.from(map['takenLog'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Helper to check if taken for a specific date and slot
  bool isTaken(DateTime date, String slot) {
    if (frequency == 'PRN') return false; 
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final takenSlots = List<String>.from(takenLog[dateKey] ?? []);
    return takenSlots.contains(slot);
  }
}
