class User {
  final String userID;
  final String email;
  final String username;
  final String userType;
  final bool gender;
  final bool hasDisability;
  final String brand;
  final String type;
  final Map<String, bool> preferences;

  User({
    required this.userID,
    required this.email,
    required this.username,
    required this.userType,
    required this.gender,
    required this.hasDisability,
    required this.brand,
    required this.type,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? '',
      gender: json['gender'] == '1', // Convert '1' to true and '0' to false
      hasDisability:
          json['hasDisability'] == '1', // Convert '1' to true and '0' to false
      brand: json['brand'] ?? '', // Default empty string if null
      type: json['type'] ?? '', // Default empty string if null
      preferences: json['preferences'] != null
          ? Map<String, bool>.from(json['preferences'])
          : {}, // Handle null preferences map
    );
  }
}
