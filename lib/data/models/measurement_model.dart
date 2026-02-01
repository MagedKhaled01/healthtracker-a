
// Import Cloud Firestore to use Timestamp class.
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the domain entity to extend it.
import '../../domain/entities/measurement.dart';

// Define a class MeasurementModel that extends the domain Measurement entity.
// This acts as a Data Transfer Object (DTO) for Firebase interactions.
class MeasurementModel extends Measurement {
  // Constructor for MeasurementModel.
  // It passes all parameters to the super class (Measurement).
  MeasurementModel({
    super.id, // Pass id to super
    required super.userId, // Pass userId to super
    required super.type, // Pass type to super
    super.value, // Pass value to super
    super.value2, // Pass value2 to super
    super.unit, // Pass unit to super
    required super.date, // Pass date to super
    super.note, // Pass note to super
  });

  // Convert the MeasurementModel object to a Map<String, dynamic>.
  // This is required for writing data to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId, // Map userId field
      'type': type.name, // Map type enum to string
      'value': value, // Map value field
      'value2': value2, // Map value2 field
      'unit': unit, // Map unit field
      // Convert Dart DateTime to Firestore Timestamp.
      'date': Timestamp.fromDate(date), 
      'note': note, // Map note field
    };
  }

  // Create a MeasurementModel factory constructor from a Map.
  // This is required for reading data from Firestore.
  // It takes the map data and the document ID.
  factory MeasurementModel.fromMap(Map<String, dynamic> map, String id) {
    return MeasurementModel(
      id: id, // Set the document ID
      userId: map['userId'] ?? '', // Get userId from map, default to empty string if null
      type: MeasurementType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'pressure'),
        orElse: () => MeasurementType.pressure,
      ), // Convert string back to enum
      value: map['value']?.toDouble(), // Get value and convert to double, null-safe
      value2: map['value2']?.toDouble(), // Get value2
      unit: map['unit'], // Get unit, can be null
      date: (map['date'] as Timestamp).toDate(), // Convert Firestore Timestamp back to Dart DateTime
      note: map['note'], // Get note, can be null
    );
  }

  // Create a factory constructor to create a MeasurementModel from a domain Measurement entity.
  // This is useful when passing data from the domain layer to the data layer.
  factory MeasurementModel.fromEntity(Measurement measurement) {
    return MeasurementModel(
      id: measurement.id, // Copy id
      userId: measurement.userId, // Copy userId
      type: measurement.type, // Copy type
      value: measurement.value, // Copy value
      value2: measurement.value2, // Copy value2
      unit: measurement.unit, // Copy unit
      date: measurement.date, // Copy date
      note: measurement.note, // Copy note
    );
  }
}
