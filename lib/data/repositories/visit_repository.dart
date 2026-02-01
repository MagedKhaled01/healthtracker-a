import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/visit_model.dart';

class VisitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  // Add a new visit
  Future<void> addVisit(VisitModel visit) async {
    if (visit.id != null) {
      await _users.doc(visit.userId).collection('visits').doc(visit.id).set(visit.toMap());
    } else {
      await _users.doc(visit.userId).collection('visits').add(visit.toMap());
    }
  }

  // Update an existing visit
  Future<void> updateVisit(VisitModel visit) async {
    if (visit.id == null) return;
    await _users
        .doc(visit.userId)
        .collection('visits')
        .doc(visit.id)
        .update(visit.toMap());
  }

  // Delete a visit
  Future<void> deleteVisit(String userId, String visitId) async {
    await _users.doc(userId).collection('visits').doc(visitId).delete();
  }

  // Get stream of visits for a user, sorted by date (newest first)
  Stream<List<VisitModel>> getUserVisits(String userId) {
    return _users
        .doc(userId)
        .collection('visits')
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VisitModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
