
// Import the Measurement entity to use it in the repository definition.
import '../entities/measurement.dart';

// Define an abstract class definition for the repository.
// This acts as a contract that any implementation must follow (Interface).
// It decouples the domain layer from the data layer implementation details.
abstract class MeasurementRepository {
  // Define a method signature for adding a measurement.
  // It takes a Measurement object as a parameter.
  // It returns a Future<void>, indicating an asynchronous operation with no return value.
  Future<void> addMeasurement(Measurement measurement);

  // Get the latest measurement of a specific type for a user.
  Future<Measurement?> getLatestMeasurement(String userId, MeasurementType type);

  // Get all measurements for a user as a stream
  Stream<List<Measurement>> getUserMeasurements(String userId);

  // Update an existing measurement
  Future<void> updateMeasurement(Measurement measurement);

  // Delete a measurement by ID
  Future<void> deleteMeasurement(String id);
}
