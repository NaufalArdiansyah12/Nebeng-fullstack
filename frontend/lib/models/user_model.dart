class User {
  final int id;
  final String name;
  final String email;
  final bool isKTPVerified;
  final int rewardPoints;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isKTPVerified,
    required this.rewardPoints,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isKTPVerified: json['is_ktp_verified'] ?? false,
      rewardPoints: json['reward_points'] ?? 0,
      profileImage: json['profile_image'],
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
    };
  }
}
