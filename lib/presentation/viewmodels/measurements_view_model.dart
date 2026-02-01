import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/repositories/measurement_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeasurementsViewModel extends ChangeNotifier {
  final MeasurementRepository _repository;
  final FirebaseAuth _auth;

  MeasurementsViewModel({
    required MeasurementRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;

  StreamSubscription<List<Measurement>>? _subscription;
  
  List<Measurement> _allMeasurements = [];
  
  // Filtered by selected type
  List<Measurement> get measurements => _allMeasurements
      .where((m) => m.type == _selectedType)
      .toList();
      
  MeasurementType _selectedType = MeasurementType.pressure;
  MeasurementType get selectedType => _selectedType;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setType(MeasurementType type) {
    _selectedType = type;
    notifyListeners();
  }

  void loadMeasurements() {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.getUserMeasurements(user.uid).listen(
      (data) {
        _allMeasurements = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addMeasurement({
    required MeasurementType type,
    double? value,
    double? value2,
    required DateTime date,
    String? note,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    if (value == null || value <= 0) {
      _errorMessage = 'Value must be greater than 0';
      notifyListeners();
      return false;
    }

    String unit = _getUnitForType(type);

    _isLoading = true;
    notifyListeners();

    try {
      final measurement = Measurement(
        userId: user.uid,
        type: type,
        value: value,
        value2: value2,
        unit: unit,
        date: date,
        note: note,
      );

      await _repository.addMeasurement(measurement);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMeasurement(Measurement measurement) async {
     _isLoading = true;
     notifyListeners();
     
     try {
       await _repository.updateMeasurement(measurement);
       _isLoading = false;
       notifyListeners();
       return true;
     } catch (e) {
       _errorMessage = e.toString();
       _isLoading = false;
       notifyListeners();
       return false;
     }
  }

  Future<void> deleteMeasurement(String id) async {
    try {
      await _repository.deleteMeasurement(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String _getUnitForType(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight: return 'kg';
      case MeasurementType.sugar: return 'mg/dL';
      case MeasurementType.pressure: return 'mmHg';
      case MeasurementType.pulse: return 'bpm';
      case MeasurementType.temperature: return '°C';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
