class AccountUser {
  const AccountUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.profileImagePath,
  });

  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? profileImagePath;

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    String field(String key) {
      final value = json[key];
      return value is String ? value : '';
    }

    return AccountUser(
      id: field('id'),
      email: field('email'),
      fullName: field('fullName'),
      phoneNumber: field('phoneNumber'),
      profileImagePath: field('profile').isEmpty ? null : field('profile'),
    );
  }
}
