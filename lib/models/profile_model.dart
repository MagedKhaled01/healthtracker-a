import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String userId;
  final String name;
  final double? height;
  final double? weight;
  final String? gender;
  final DateTime createdAt;

  ProfileModel({
    required this.userId,
    required this.name,
    this.height,
    this.weight,
    this.gender,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'height': height,
      'weight': weight,
      'gender': gender,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      gender: map['gender'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
