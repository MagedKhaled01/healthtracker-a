
// Profile entity representing user's core health data.
class Profile {
  final String userId;
  final String? name;
  final double? height; // in cm
  final double? weight; // in kg

  Profile({
    required this.userId,
    this.name,
    this.height,
    this.weight,
  });
}
