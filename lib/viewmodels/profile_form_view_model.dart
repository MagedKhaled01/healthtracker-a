
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileFormViewModel extends ChangeNotifier {
  final ProfileService _service;
  final FirebaseAuth _auth;

  ProfileFormViewModel({ProfileService? service, FirebaseAuth? auth})
      : _service = service ?? ProfileService(),
        _auth = auth ?? FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> submitProfile({
    required String name,
    String? height,
    String? weight,
    String? gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (name.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      double? heightVal;
      if (height != null && height.trim().isNotEmpty) {
        heightVal = double.tryParse(height);
        if (heightVal == null || heightVal <= 0) {
          throw Exception('Invalid height');
        }
      }

      double? weightVal;
      if (weight != null && weight.trim().isNotEmpty) {
        weightVal = double.tryParse(weight);
        if (weightVal == null || weightVal <= 0) {
          throw Exception('Invalid weight');
        }
      }

      final profile = ProfileModel(
        userId: user.uid,
        name: name.trim(),
        height: heightVal,
        weight: weightVal,
        gender: gender,
        createdAt: DateTime.now(),
      );

      await _service.saveProfile(profile);
      
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
}
