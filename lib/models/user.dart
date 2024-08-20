class User {
  final String userID;
  final String email;
  final String username;
  final String userType;
  final String gender;
  final bool hasDisability;

  User({
    required this.userID,
    required this.email,
    required this.username,
    required this.userType,
    required this.gender,
    required this.hasDisability,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? '',
      gender: json['gender'] ?? '',
      hasDisability: json['hasDisability'] == '1',
    );
  }
}
