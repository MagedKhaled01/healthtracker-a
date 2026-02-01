import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/visit_repository.dart';
import '../../models/visit_model.dart';
import 'dart:async';

class VisitsViewModel extends ChangeNotifier {
  final VisitRepository _repository = VisitRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<VisitModel> _visits = [];
  List<VisitModel> _filteredVisits = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Set<String> _selectedSpecialties = {};

  List<VisitModel> get visits => _filteredVisits;
  bool get isLoading => _isLoading;

  StreamSubscription? _subscription;

  // Specialties derived from current visits
  Set<String> get availableSpecialties {
    return _visits
        .map((v) => v.specialty)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet();
  }
  
  Set<String> get selectedSpecialties => _selectedSpecialties;

  void loadVisits() {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.getUserVisits(user.uid).listen((visitsData) {
      _visits = visitsData;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    });
  }

  void searchVisits(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void toggleSpecialtyFilter(String specialty) {
    if (_selectedSpecialties.contains(specialty)) {
      _selectedSpecialties.remove(specialty);
    } else {
      _selectedSpecialties.add(specialty);
    }
    _applyFilters();
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedSpecialties.clear();
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredVisits = _visits.where((visit) {
      final matchesSearch = _searchQuery.isEmpty ||
          visit.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (visit.clinicName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesSpecialty = _selectedSpecialties.isEmpty ||
          (_selectedSpecialties.contains(visit.specialty));

      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  Future<void> addVisit(VisitModel visit) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addVisit(visit);
    } catch (e) {
      debugPrint("Error adding visit: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVisit(VisitModel visit) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateVisit(visit);
    } catch (e) {
      debugPrint("Error updating visit: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVisit(String visitId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _repository.deleteVisit(user.uid, visitId);
    } catch (e) {
      debugPrint("Error deleting visit: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
