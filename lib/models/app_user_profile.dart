class AppUserProfile {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? avatarUrl;

  AppUserProfile({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.avatarUrl,
  });

  factory AppUserProfile.fromMap(Map<String, dynamic> m) {
    return AppUserProfile(
      id: '${m['id'] ?? ''}',
      fullName: '${m['full_name'] ?? ''}',
      mobileNumber: '${m['mobile_number'] ?? m['phone'] ?? ''}',
      email: m['email']?.toString(),
      avatarUrl: m['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toUpdate() {
    return {
      'full_name': fullName.trim(),
      'phone': mobileNumber.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}