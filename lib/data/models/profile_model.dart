
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  ProfileModel({
    required super.userId,
    super.name,
    super.height,
    super.weight,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return ProfileModel(
      userId: map['userId'] ?? id,
      name: map['name'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
    );
  }

  factory ProfileModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document does not exist');
    }
    return ProfileModel.fromMap(data, doc.id);
  }
}
