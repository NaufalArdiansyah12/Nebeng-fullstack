class PaymentModel {
  final int id;
  final int rideId;
  final int userId;
  final String bookingNumber;
  final String paymentMethod;
  final double amount;
  final double adminFee;
  final double totalAmount;
  final String externalId;
  final String? virtualAccountNumber;
  final String? bankCode;
  final String status;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.bookingNumber,
    required this.paymentMethod,
    required this.amount,
    required this.adminFee,
    required this.totalAmount,
    required this.externalId,
    this.virtualAccountNumber,
    this.bankCode,
    required this.status,
    this.expiresAt,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      rideId: json['ride_id'],
      userId: json['user_id'],
      bookingNumber: json['booking_number'],
      paymentMethod: json['payment_method'],
      amount: double.parse(json['amount'].toString()),
      adminFee: double.parse(json['admin_fee'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      externalId: json['external_id'],
      virtualAccountNumber: json['virtual_account_number'],
      bankCode: json['bank_code'],
      status: json['status'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'user_id': userId,
      'booking_number': bookingNumber,
      'payment_method': paymentMethod,
      'amount': amount,
      'admin_fee': adminFee,
      'total_amount': totalAmount,
      'external_id': externalId,
      'virtual_account_number': virtualAccountNumber,
      'bank_code': bankCode,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
