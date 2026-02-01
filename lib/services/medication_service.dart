import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _medications => _firestore.collection('medications');

  // Add a new medication
  Future<DocumentReference> addMedication(Medication medication) async {
    return await _medications.add(medication.toMap());
  }

  // Update an existing medication
  Future<void> updateMedication(Medication medication) async {
    if (medication.id == null) return;
    await _medications.doc(medication.id).update(medication.toMap());
  }

  // Get stream of ACTIVE medications for a user
  Stream<List<Medication>> getUserMedications(String userId) {
    return _medications
        .where('userId', isEqualTo: userId)
        // .where('isActive', isEqualTo: true) // Removed, we handle visibility logic in app or via end date
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        return Medication.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Sort client-side
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  // Mark medication taken for a specific date and slot
  Future<void> logIntake(String medicationId, DateTime date, String slot, bool isTaken) async {
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final fieldPath = 'takenLog.$dateKey';

    if (isTaken) {
      await _medications.doc(medicationId).update({
        fieldPath: FieldValue.arrayUnion([slot])
      });
    } else {
      await _medications.doc(medicationId).update({
        fieldPath: FieldValue.arrayRemove([slot])
      });
    }
  }

  // Delete medication (Permanent delete as requested)
  // Or soft delete by setting isActive = false if preferred, but user said "Permanently remove".
  Future<void> deleteMedication(String medicationId) async {
    await _medications.doc(medicationId).delete();
  }
}
