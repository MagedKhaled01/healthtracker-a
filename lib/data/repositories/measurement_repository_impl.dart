
// Import Firestore for database operations.
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the Measurement entity.
import '../../domain/entities/measurement.dart';
// Import the Repository interface.
import '../../domain/repositories/measurement_repository.dart';
// Import the MeasurementModel DTO for mapping.
import '../models/measurement_model.dart';

// Implement the MeasurementRepository interface.
// This class is responsible for the actual data operations (Data Layer).
class MeasurementRepositoryImpl implements MeasurementRepository {
  // Get an instance of FirebaseFirestore.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Implement the addMeasurement method defined in the interface.
  // This method adds a measurement to the Firestore database.
  @override
  Future<void> addMeasurement(Measurement measurement) async {
    // Convert the domain entity (Measurement) to a data model (MeasurementModel).
    // The data model knows how to convert itself to a Map for Firestore.
    final model = MeasurementModel.fromEntity(measurement);
    
    // Add the converted map to the 'measurements' collection in Firestore.
    // 'add' automatically generates a unique ID for the document.
    await _db.collection('measurements').add(model.toMap());
  }

  @override
  Future<Measurement?> getLatestMeasurement(String userId, MeasurementType type) async {
    final query = await _db
        .collection('measurements')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return MeasurementModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  @override
  Stream<List<Measurement>> getUserMeasurements(String userId) {
    return _db
        .collection('measurements')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeasurementModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> updateMeasurement(Measurement measurement) async {
    if (measurement.id == null) return;
    final model = MeasurementModel.fromEntity(measurement);
    await _db.collection('measurements').doc(measurement.id).update(model.toMap());
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    await _db.collection('measurements').doc(id).delete();
  }
}
