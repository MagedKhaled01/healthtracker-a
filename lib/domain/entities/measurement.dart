
// Define a class named Measurement to represent the data structure in the domain layer.
// This entity is pure Dart and does not depend on any external libraries like Flutter or Firebase.

// Enum for Measurement Type
enum MeasurementType {
  pressure,
  sugar,
  weight,
  pulse,
  temperature,
}

class Measurement {
  // Optional String to store the unique specific ID of the measurement document.
  final String? id;
  
  // Required String to link this measurement to a specific user.
  final String userId;
  
  // Required MeasurementType for the type of measurement.
  final MeasurementType type; 
  
  // Optional double to store the numeric value of the measurement.
  final double? value;
  
  // Optional String to store the unit of measurement (e.g., 'kg', 'mg/dL').
  final String? unit;
  
  // Required DateTime to record when the measurement was taken.
  final DateTime date;
  
  // Optional String for any additional notes the user wants to add.
  final String? note;

  // Constructor to initialize the Measurement object with named parameters.
  Measurement({
    this.id, // Initialize id (optional)
    required this.userId, // Initialize userId (required)
    required this.type, // Initialize type (required)
    this.value, // Initialize value (optional)
    this.unit, // Initialize unit (optional)
    required this.date, // Initialize date (required)
    this.note, // Initialize note (optional)
  });
}
