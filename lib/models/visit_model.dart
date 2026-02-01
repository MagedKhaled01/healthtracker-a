import 'package:cloud_firestore/cloud_firestore.dart';

class VisitModel {
  final String? id;
  final String userId;
  final String doctorName;
  final DateTime visitDate;
  final String? clinicName;
  final String? specialty;
  final String? notes;
  final String? attachmentUrl; // Optional URL for image/PDF
  final DateTime createdAt;

  VisitModel({
    this.id,
    required this.userId,
    required this.doctorName,
    required this.visitDate,
    this.clinicName,
    this.specialty,
    this.notes,
    this.attachmentUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'doctorName': doctorName,
      'visitDate': Timestamp.fromDate(visitDate),
      'clinicName': clinicName,
      'specialty': specialty,
      'notes': notes,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VisitModel.fromMap(Map<String, dynamic> map, String id) {
    return VisitModel(
      id: id,
      userId: map['userId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      visitDate: (map['visitDate'] as Timestamp).toDate(),
      clinicName: map['clinicName'],
      specialty: map['specialty'],
      notes: map['notes'],
      attachmentUrl: map['attachmentUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  VisitModel copyWith({
    String? id,
    String? userId,
    String? doctorName,
    DateTime? visitDate,
    String? clinicName,
    String? specialty,
    String? notes,
    String? attachmentUrl,
    DateTime? createdAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorName: doctorName ?? this.doctorName,
      visitDate: visitDate ?? this.visitDate,
      clinicName: clinicName ?? this.clinicName,
      specialty: specialty ?? this.specialty,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
