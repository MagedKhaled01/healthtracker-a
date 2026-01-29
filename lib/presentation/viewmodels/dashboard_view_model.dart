
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/measurement.dart';

class DashboardViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final MeasurementRepository _measurementRepository;
  final FirebaseAuth _auth;

  DashboardViewModel({
    required ProfileRepository profileRepository,
    required MeasurementRepository measurementRepository,
    FirebaseAuth? auth,
  })  : _profileRepository = profileRepository,
        _measurementRepository = measurementRepository,
        _auth = auth ?? FirebaseAuth.instance;

  // State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Profile? _profile;
  Profile? get profile => _profile;

  Measurement? _latestPressure;
  Measurement? get latestPressure => _latestPressure;

  Measurement? _latestSugar;
  Measurement? get latestSugar => _latestSugar;

  Measurement? _latestWeight;
  Measurement? get latestWeight => _latestWeight;

  double? _bmi;
  double? get bmi => _bmi;

  // Effective Weight (Measurement > Profile)
  double? get currentWeight => _latestWeight?.value ?? _profile?.weight;

  // Initial Data Load
  Future<void> loadDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch Profile
      _profile = await _profileRepository.getProfile(user.uid);

      // Fetch Latest Measurements
      _latestPressure = await _measurementRepository.getLatestMeasurement(user.uid, MeasurementType.pressure);
      _latestSugar = await _measurementRepository.getLatestMeasurement(user.uid, MeasurementType.sugar);
      _latestWeight = await _measurementRepository.getLatestMeasurement(user.uid, MeasurementType.weight);

      // Calculate BMI
      // Priority: Use weight from latest measurement, fallback to profile
      final weight = _latestWeight?.value ?? _profile?.weight;
      final height = _profile?.height;

      if (weight != null && height != null && height > 0) {
        final heightInMeters = height / 100;
        _bmi = weight / (heightInMeters * heightInMeters);
      } else {
        _bmi = null;
      }

    } catch (e) {
      // Handle error cleanly
      debugPrint("Error loading dashboard data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
