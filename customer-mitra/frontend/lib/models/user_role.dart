/// Enum untuk role user di aplikasi Nebeng
enum UserRole {
  customer('customer'),
  mitra('mitra'),
  posmitra('posmitra'),
  admin('admin'),
  superadmin('superadmin'),
  finance('finance');

  final String value;

  const UserRole(this.value);

  /// Convert dari string ke UserRole enum
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'mitra':
        return UserRole.mitra;
      case 'posmitra':
      case 'pos_mitra':
        return UserRole.posmitra;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
      case 'super_admin':
        return UserRole.superadmin;
      case 'finance':
        return UserRole.finance;
      default:
        return UserRole.customer; // default fallback
    }
  }

  /// Check apakah role adalah customer
  bool get isCustomer => this == UserRole.customer;

  /// Check apakah role adalah mitra
  bool get isMitra => this == UserRole.mitra;

  /// Check apakah role adalah pos mitra
  bool get isPosMitra => this == UserRole.posmitra;

  /// Check apakah role adalah admin
  bool get isAdmin => this == UserRole.admin;

  /// Check apakah role adalah superadmin
  bool get isSuperAdmin => this == UserRole.superadmin;

  /// Check apakah role adalah finance
  bool get isFinance => this == UserRole.finance;

  @override
  String toString() => value;
}
