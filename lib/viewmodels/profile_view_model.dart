
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _service;
  final FirebaseAuth _auth;

  ProfileViewModel({ProfileService? service, FirebaseAuth? auth})
      : _service = service ?? ProfileService(),
        _auth = auth ?? FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _name = '';
  String get name => _name;

  String _height = '';
  String get height => _height;
  
  String _weight = '';
  String get weight => _weight;
  
  String? _gender;
  String? get gender => _gender;

  // Initialize data
  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _service.getProfile(user.uid);
      if (profile != null) {
        _name = profile.name;
        _height = profile.height?.toString() ?? '';
        _weight = profile.weight?.toString() ?? '';
        _gender = profile.gender;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Setters for UI binding
  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setHeight(String value) {
    _height = value;
    notifyListeners();
  }
  
  void setWeight(String value) {
    _weight = value;
    notifyListeners();
  }
  
  void setGender(String? value) {
    _gender = value;
    notifyListeners();
  }

  // Save logic
  Future<bool> saveProfile() async {
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
      if (_name.trim().isEmpty) {
         throw Exception('Name cannot be empty');
      }

      double? heightVal;
      if (_height.trim().isNotEmpty) {
        heightVal = double.tryParse(_height);
        if (heightVal == null || heightVal <= 0) {
          throw Exception('Invalid height');
        }
      }
      
      double? weightVal;
      if (_weight.trim().isNotEmpty) {
        weightVal = double.tryParse(_weight);
        if (weightVal == null || weightVal <= 0) {
          throw Exception('Invalid weight');
        }
      }

      final profile = ProfileModel(
        userId: user.uid,
        name: _name.trim(),
        height: heightVal,
        weight: weightVal,
        gender: _gender,
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
