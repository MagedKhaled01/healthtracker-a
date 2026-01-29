
// Import foundation for basic Flutter classes like ChangeNotifier.
import 'package:flutter/foundation.dart';
// Import dependencies.
import '../../domain/entities/measurement.dart';
import '../../domain/repositories/measurement_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define MeasurementsViewModel class that extends ChangeNotifier.
// This class manages the state for the MeasurementsScreen (Presentation Logic).
// It notifies listeners (the UI) when state changes.
class MeasurementsViewModel extends ChangeNotifier {
  // Reference to the repository to perform data operations.
  final MeasurementRepository _repository;
  // Reference to FirebaseAuth to get the current user.
  final FirebaseAuth _auth;

  // Constructor with dependency injection.
  // Allows injecting a specific repository implementation (good for testing).
  // Defaults to FirebaseAuth.instance if not provided.
  MeasurementsViewModel({
    required MeasurementRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;

  // State variable to track loading status.
  bool _isLoading = false;
  // Getter for isLoading to expose it to the UI (read-only).
  bool get isLoading => _isLoading;

  // State variable to track error messages.
  String? _errorMessage;
  // Getter for errorMessage.
  String? get errorMessage => _errorMessage;

  // Function to add a measurement.
  // Called by the UI when the user clicks 'Save'.
  // Returns true if successful, false otherwise.
  Future<bool> addMeasurement({
    required MeasurementType type,
    double? value,
    required DateTime date,
    String? note,
  }) async {
    // Get the current logged-in user.
    final user = _auth.currentUser;
    
    // Check if user is logged in.
    if (user == null) {
      _errorMessage = 'User must be logged in'; // Set error message
      notifyListeners(); // Notify UI to update
      return false;
    }

    // STRICT VALIDATION
    if (value == null || value <= 0) {
      _errorMessage = 'Value must be greater than 0';
      notifyListeners();
      return false;
    }

    // Determine unit automatically based on type
    String unit;
    switch (type) {
      case MeasurementType.weight:
        unit = 'kg';
        break;
      case MeasurementType.sugar:
        unit = 'mg/dL';
        break;
      case MeasurementType.pressure:
        unit = 'mmHg';
        break;
      case MeasurementType.pulse:
        unit = 'bpm';
        break;
      case MeasurementType.temperature:
        unit = '°C';
        break;
    }

    // Set loading state to true.
    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners(); // Notify UI to show loading spinner

    try {
      // Create a Measurement domain entity.
      final measurement = Measurement(
        userId: user.uid,
        type: type,
        value: value,
        unit: unit,
        date: date,
        note: note,
      );

      // Call the repository to save the measurement.
      await _repository.addMeasurement(measurement);
      
      // If successful, stop loading.
      _isLoading = false;
      notifyListeners(); // Notify UI
      return true;
    } catch (e) {
      // If an error occurs, capture it and stop loading.
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners(); // Notify UI to show error
      return false;
    }
  }
}
