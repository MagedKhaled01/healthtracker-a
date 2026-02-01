import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';

import 'mixins/selection_view_model_mixin.dart';

class MedicationViewModel extends ChangeNotifier with SelectionViewModelMixin<String> {
  final MedicationService _service;
  final NotificationService _notifications;
  final FirebaseAuth _auth;
  MedicationViewModel({
    MedicationService? service, 
    NotificationService? notifications,
    FirebaseAuth? auth
  })  : _service = service ?? MedicationService(),
        _notifications = notifications ?? NotificationService(),
        _auth = auth ?? FirebaseAuth.instance;

  StreamSubscription<List<Medication>>? _medicationsSubscription;

  List<Medication> _medications = [];
  List<Medication> get medications => _medications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Helper for dashboard: Pending medications for TODAY
  List<Map<String, dynamic>> get pendingMedicationsForToday {
    final now = DateTime.now();
    List<Map<String, dynamic>> pending = [];

    for (var med in _medications) {
       if (!med.isActiveOn(now)) continue;
       for (var timeStr in med.doseTimes) {
          if (!med.isTaken(now, timeStr)) {
            pending.add({'med': med, 'slot': timeStr});
          }
       }
    }
    
    pending.sort((a, b) => (a['slot'] as String).compareTo(b['slot'] as String));
    return pending;
  }

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
          debugPrint('Medication stream fired with ${meds.length} medications');
          _medications = meds;
          _isLoading = false;
          _scheduleNotificationsForBatch(meds); // Refresh notifications
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
  void _scheduleNotificationsForBatch(List<Medication> meds) {
    for (var med in meds) {
       if (med.endDate == null || med.endDate!.isAfter(DateTime.now())) {
          _updateNextDoseAndSchedule(med);
       }
    }
  }

  Future<bool> addMedication({
    required String name,
    String? dosage,
    required String frequency, // 1x, 2x, 3x, PRN
    required List<TimeOfDay> doseTimes, // New: List of TimeOfDay
    String timeMode = 'simple',
    required DateTime startDate,
    int? durationDays, // 3, 7, 14. If null, Ongoing.
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
      DateTime? endDate;
      if (durationDays != null) {
        endDate = startDate.add(Duration(days: durationDays));
      }

      // Calculate string times based on frequency & input
      List<String> calculatedTimes = [];
      
      if (frequency == 'PRN') {
        calculatedTimes = []; // No fixed times
      } else if (timeMode == 'advanced') {
        // Use user provided times exactly
        calculatedTimes = doseTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();
      } else {
        // Quick Mode Logic
        if (doseTimes.isEmpty) {
           calculatedTimes = ['08:00'];
        } else {
           final first = doseTimes.first;
           // 1x
           calculatedTimes.add('${first.hour.toString().padLeft(2, '0')}:${first.minute.toString().padLeft(2, '0')}');
           
           if (frequency == '2x') {
             // +12 hours
             final second = TimeOfDay(hour: (first.hour + 12) % 24, minute: first.minute);
             calculatedTimes.add('${second.hour.toString().padLeft(2, '0')}:${second.minute.toString().padLeft(2, '0')}');
           } else if (frequency == '3x') {
             // +8, +16 hours
             final second = TimeOfDay(hour: (first.hour + 8) % 24, minute: first.minute);
             final third = TimeOfDay(hour: (first.hour + 16) % 24, minute: first.minute);
             calculatedTimes.add('${second.hour.toString().padLeft(2, '0')}:${second.minute.toString().padLeft(2, '0')}');
             calculatedTimes.add('${third.hour.toString().padLeft(2, '0')}:${third.minute.toString().padLeft(2, '0')}');
           }
        }
      }

      final medication = Medication(
        userId: user.uid,
        name: name,
        dosage: dosage,
        frequency: frequency,
        doseTimes: calculatedTimes,
        timeMode: timeMode,
        startDate: startDate,
        endDate: endDate,
        intakeRule: intakeRule,
        createdAt: DateTime.now(),
      );

      final docRef = await _service.addMedication(medication);
      
      // Calculate next dose for the newly added medication and schedule it
      final newMedWithId = Medication(
        id: docRef.id,
        userId: medication.userId,
        name: medication.name,
        dosage: medication.dosage,
        frequency: medication.frequency,
        doseTimes: medication.doseTimes,
        timeMode: medication.timeMode,
        startDate: medication.startDate,
        endDate: medication.endDate,
        intakeRule: medication.intakeRule,
        createdAt: medication.createdAt,
      );
      
      await _updateNextDoseAndSchedule(newMedWithId);
      
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

  // NEW Logic: Calculate next dose dynamically
  Future<void> _updateNextDoseAndSchedule(Medication med) async {
    if (med.doseTimes.isEmpty) return;

    final now = DateTime.now();
    DateTime? nextDose;
    
    // 1. Sort times
    var times = List<String>.from(med.doseTimes);
    times.sort();

    // 2. Find earliest time > now for Today
    for (var t in times) {
       final parts = t.split(':');
       if (parts.length != 2) continue;
       final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
       
       if (dt.isAfter(now)) {
         nextDose = dt;
         break;
       }
    }

    // 3. If no time left today, pick earliest time Tomorrow
    if (nextDose == null) {
       final parts = times.first.split(':');
       nextDose = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1])).add(const Duration(days: 1));
    }

    // 4. Update Model (Offline first)
    final updatedMed = Medication(
        id: med.id, 
        userId: med.userId, 
        name: med.name, 
        frequency: med.frequency, 
        doseTimes: med.doseTimes, 
        startDate: med.startDate, 
        intakeRule: med.intakeRule, 
        createdAt: med.createdAt,
        dosage: med.dosage,
        endDate: med.endDate,
        takenLog: med.takenLog,
        timeMode: med.timeMode,
        nextDoseAt: nextDose
    );

    // Update local list
    final index = _medications.indexWhere((m) => m.id == med.id);
    if (index != -1) {
      _medications[index] = updatedMed;
    }

    // 5. Schedule ONE-SHOT
    if (nextDose != null) {
       await _notifications.scheduleOneShotAlarm(
         med.id!, 
         "Time for ${med.name}", 
         "It's time to take your medication.", 
         nextDose
       );
    }
  }

  Future<bool> updateMedication({
    required String id,
    required List<String> previousDoseTimes,
    required String name,
    String? dosage,
    required String frequency,
    required List<TimeOfDay> doseTimes,
    String timeMode = 'simple',
    required DateTime startDate,
    int? durationDays,
    required String intakeRule,
    required DateTime createdAt,
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
      // 1. Cancel old reminders
      await _notifications.cancelReminders(id, previousDoseTimes);

      // 2. Prepare new data
      DateTime? endDate;
      if (durationDays != null) {
        endDate = startDate.add(Duration(days: durationDays));
      }

      List<String> calculatedTimes = [];
      if (frequency == 'PRN') {
        calculatedTimes = [];
      } else if (timeMode == 'advanced') {
        calculatedTimes = doseTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();
      } else {
        if (doseTimes.isEmpty) {
           calculatedTimes = ['08:00'];
        } else {
           final first = doseTimes.first;
           calculatedTimes.add('${first.hour.toString().padLeft(2, '0')}:${first.minute.toString().padLeft(2, '0')}');
           
           if (frequency == '2x') {
             final second = TimeOfDay(hour: (first.hour + 12) % 24, minute: first.minute);
             calculatedTimes.add('${second.hour.toString().padLeft(2, '0')}:${second.minute.toString().padLeft(2, '0')}');
           } else if (frequency == '3x') {
             final second = TimeOfDay(hour: (first.hour + 8) % 24, minute: first.minute);
             final third = TimeOfDay(hour: (first.hour + 16) % 24, minute: first.minute);
             calculatedTimes.add('${second.hour.toString().padLeft(2, '0')}:${second.minute.toString().padLeft(2, '0')}');
             calculatedTimes.add('${third.hour.toString().padLeft(2, '0')}:${third.minute.toString().padLeft(2, '0')}');
           }
        }
      }

      final medication = Medication(
        id: id,
        userId: user.uid,
        name: name,
        dosage: dosage,
        frequency: frequency,
        doseTimes: calculatedTimes,
        timeMode: timeMode,
        startDate: startDate,
        endDate: endDate,
        intakeRule: intakeRule,
        createdAt: createdAt,
      );

      await _service.updateMedication(medication);
      
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
      
      // Reschedule next dose immediately after intake
      final medIndex = _medications.indexWhere((m) => m.id == medicationId);
      if (medIndex != -1) {
        // We need to fetch the latest state or just re-run the schedule logic on the existing object
        // The existing object might need a refresh from DB ideally, but for now we calculate based on rules.
        await _updateNextDoseAndSchedule(_medications[medIndex]);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      final med = _medications.firstWhere((m) => m.id == medicationId, orElse: () => Medication(
          id: 'temp', userId: '', name: '', frequency: '', doseTimes: [], startDate: DateTime.now(), intakeRule: 'none', createdAt: DateTime.now()
      ));
      
      await _service.deleteMedication(medicationId);
      
      if (med.id != 'temp') {
         // Cancel by ID (using the hashCode convention we set up)
         await _notifications.cancelNotification(med.id.hashCode);
      }
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
