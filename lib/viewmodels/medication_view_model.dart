import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';

class MedicationViewModel extends ChangeNotifier {
  final MedicationService _service;
  final FirebaseAuth _auth;
  StreamSubscription<List<Medication>>? _medicationsSubscription;

  MedicationViewModel({MedicationService? service, FirebaseAuth? auth})
      : _service = service ?? MedicationService(),
        _auth = auth ?? FirebaseAuth.instance;

  List<Medication> _medications = [];
  List<Medication> get medications => _medications;

  // Group helpers
  List<Medication> get morningMedications =>
      _medications.where((m) => m.timeSlots.contains('Morning')).toList();

  List<Medication> get afternoonMedications =>
      _medications.where((m) => m.timeSlots.contains('Afternoon')).toList();

  List<Medication> get eveningMedications =>
      _medications.where((m) => m.timeSlots.contains('Evening')).toList();

  List<Medication> get prnMedications =>
      _medications.where((m) => m.frequency == 'PRN').toList();

  // Helper for dashboard: Pending medications for TODAY
  // Returns a list of (Medication, Slot) pairs that are NOT taken today
  // Should NOT include PRN
  List<Map<String, dynamic>> get pendingMedicationsForToday {
    final now = DateTime.now();
    List<Map<String, dynamic>> pending = [];

    // Helper to check and add
    void checkAndAdd(List<Medication> list, String slot) {
       for (var med in list) {
          // Check start date
          if (now.isBefore(med.startDate)) continue;
          
          if (!med.isTaken(now, slot)) {
            pending.add({'med': med, 'slot': slot});
          }
       }
    }

    checkAndAdd(morningMedications, 'Morning');
    checkAndAdd(afternoonMedications, 'Afternoon');
    checkAndAdd(eveningMedications, 'Evening');
    
    // Sort by slot order roughly (Morning < Afternoon < Evening)
    // Map order insertion is preserved, so if we add in order, it's sorted.
    return pending;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadMedications() {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medicationsSubscription?.cancel();
      _medicationsSubscription = _service.getUserMedications(user.uid).listen(
        (meds) {
          _medications = meds;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedication({
    required String name,
    String? dosage,
    required String frequency, // 1x, 2x, 3x, PRN
    required List<String> timeSlots, // Morning, Afternoon, Evening
    String timeMode = 'simple',
    required DateTime startDate,
    required String intakeRule,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    if (name.isEmpty) {
      _errorMessage = 'Name is required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final medication = Medication(
        userId: user.uid,
        name: name,
        dosage: dosage,
        frequency: frequency,
        timeSlots: timeSlots,
        timeMode: timeMode,
        startDate: startDate,
        intakeRule: intakeRule,
        createdAt: DateTime.now(),
      );

      await _service.addMedication(medication);
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

  Future<void> logIntake(String medicationId, String slot, bool isTaken) async {
    try {
      final now = DateTime.now();
      await _service.logIntake(medicationId, now, slot, isTaken);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _service.deleteMedication(medicationId);
      // No need to notify/update list manually as stream will handle it
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _medicationsSubscription?.cancel();
    super.dispose();
  }
}
