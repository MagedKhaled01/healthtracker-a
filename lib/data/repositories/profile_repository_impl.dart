
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<Profile?> getProfile(String userId) async {
    try {
      final doc = await _db.collection('profiles').doc(userId).get();
      if (doc.exists) {
        return ProfileModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      // In a real app, log error
      return null;
    }
  }
}
