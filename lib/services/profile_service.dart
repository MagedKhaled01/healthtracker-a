import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _db.collection('profiles').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return ProfileModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      // In a real app, log error
      return null;
    }
  }

  Future<void> saveProfile(ProfileModel profile) async {
    await _db
        .collection('profiles')
        .doc(profile.userId)
        .set(profile.toMap());
  }
}
