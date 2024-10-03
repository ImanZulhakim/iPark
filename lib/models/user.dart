class User {
  final String userID;
  final String email;
  final String username;
  final String userType;
  final bool gender; // true for male, false for female
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

  // Copy the user object with optional updated fields
  User copyWith({
    String? userID,
    String? email,
    String? username,
    String? userType,
    bool? gender,
    bool? hasDisability,
    String? brand,
    String? type,
    Map<String, bool>? preferences,
  }) {
    return User(
      userID: userID ?? this.userID,
      email: email ?? this.email,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      gender: gender ?? this.gender,
      hasDisability: hasDisability ?? this.hasDisability,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      preferences: preferences ?? this.preferences,
    );
  }

  // Factory constructor to create a User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? '',
      gender: json['gender'] == '1', // Convert '1' to true and '0' to false
      hasDisability: json['hasDisability'] == '1', // Handle '1' or '0'
      brand: json['brand'] ?? '', // Use empty string if brand is null
      type: json['type'] ?? '', // Use empty string if type is null
      preferences: json['preferences'] != null
          ? Map<String, bool>.from(json['preferences'])
          : {}, // Handle null preferences safely
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'email': email,
      'username': username,
      'userType': userType,
      'gender': gender ? '1' : '0', // Convert bool to '1' or '0'
      'hasDisability': hasDisability ? '1' : '0', // Convert bool to '1' or '0'
      'brand': brand,
      'type': type,
      'preferences': preferences,
    };
  }
}
