
import '../entities/profile.dart';

// Interface for fetching and updating profile data.
abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
}
