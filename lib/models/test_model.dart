import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String? id;
  final String userId;
  final String testName;
  final DateTime testDate;
  final String? result; // Flexible: "Positive", "120 mg/dL", etc.
  final String? notes;
  final String? attachmentUrl; // Optional URL for image/PDF
  final DateTime createdAt;

  TestModel({
    this.id,
    required this.userId,
    required this.testName,
    required this.testDate,
    this.result,
    this.notes,
    this.attachmentUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'testName': testName,
      'testDate': Timestamp.fromDate(testDate),
      'result': result,
      'notes': notes,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map, String id) {
    return TestModel(
      id: id,
      userId: map['userId'] ?? '',
      testName: map['testName'] ?? '',
      testDate: (map['testDate'] as Timestamp).toDate(),
      result: map['result'],
      notes: map['notes'],
      attachmentUrl: map['attachmentUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  TestModel copyWith({
    String? id,
    String? userId,
    String? testName,
    DateTime? testDate,
    String? result,
    String? notes,
    String? attachmentUrl,
    DateTime? createdAt,
  }) {
    return TestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testName: testName ?? this.testName,
      testDate: testDate ?? this.testDate,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
