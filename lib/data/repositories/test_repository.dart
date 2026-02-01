import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/test_model.dart';

class TestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  // Add a new test
  Future<void> addTest(TestModel test) async {
    if (test.id != null) {
      await _users.doc(test.userId).collection('tests').doc(test.id).set(test.toMap());
    } else {
      await _users.doc(test.userId).collection('tests').add(test.toMap());
    }
  }

  // Update an existing test
  Future<void> updateTest(TestModel test) async {
    if (test.id == null) return;
    await _users
        .doc(test.userId)
        .collection('tests')
        .doc(test.id)
        .update(test.toMap());
  }

  // Delete a test
  Future<void> deleteTest(String userId, String testId) async {
    await _users.doc(userId).collection('tests').doc(testId).delete();
  }

  // Get stream of tests for a user, sorted by date (newest first)
  Stream<List<TestModel>> getUserTests(String userId) {
    return _users
        .doc(userId)
        .collection('tests')
        .orderBy('testDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
