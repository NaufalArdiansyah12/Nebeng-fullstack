class User {
  final int id;
  final String name;
  final String email;
  final bool isKTPVerified;
  final int rewardPoints;
  final String? profileImage;
  final String? phone;
  final bool phoneVerified;
  final String role; // customer, mitra, posmitra, admin, etc

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isKTPVerified,
    required this.rewardPoints,
    this.profileImage,
    this.phone,
    this.phoneVerified = false,
    this.role = 'customer',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isKTPVerified: json['is_ktp_verified'] ?? false,
      rewardPoints: json['reward_points'] ?? 0,
      profileImage: json['profile_image'],
      phone: json['phone'],
      phoneVerified: json['phone_verified'] ?? false,
      role: json['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_ktp_verified': isKTPVerified,
      'reward_points': rewardPoints,
      'profile_image': profileImage,
      'phone': phone,
      'phone_verified': phoneVerified,
      'role': role,
    };
  }
}
