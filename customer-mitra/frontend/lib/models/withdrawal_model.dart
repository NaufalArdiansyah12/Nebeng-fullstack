class WithdrawalModel {
  final int id;
  final String transactionId;
  final double amount;
  final double adminFee;
  final double totalAmount;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final String status;
  final String? submittedAt;
  final String? completedAt;
  final List<ProgressItem>? progress;
  final String? estimatedDuration;

  WithdrawalModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.adminFee,
    required this.totalAmount,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.status,
    this.submittedAt,
    this.completedAt,
    this.progress,
    this.estimatedDuration,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      amount: double.parse(json['amount']?.toString() ?? '0'),
      adminFee: double.parse(json['admin_fee']?.toString() ?? '0'),
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0'),
      bankName: json['bank_name'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      bankAccountName: json['bank_account_name'] ?? '',
      status: json['status'] ?? '',
      submittedAt: json['submitted_at'],
      completedAt: json['completed_at'],
      progress: json['progress'] != null
          ? (json['progress'] as List)
              .map((item) => ProgressItem.fromJson(item))
              .toList()
          : null,
      estimatedDuration: json['estimated_duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'amount': amount,
      'admin_fee': adminFee,
      'total_amount': totalAmount,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'status': status,
      'submitted_at': submittedAt,
      'completed_at': completedAt,
      'progress': progress?.map((item) => item.toJson()).toList(),
      'estimated_duration': estimatedDuration,
    };
  }
}

class ProgressItem {
  final String title;
  final String description;
  final String? date;
  final String? time;
  final bool completed;

  ProgressItem({
    required this.title,
    required this.description,
    this.date,
    this.time,
    required this.completed,
  });

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    return ProgressItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'],
      time: json['time'],
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'completed': completed,
    };
  }
}

class BalanceInfo {
  final String name;
  final double balance;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;

  BalanceInfo({
    required this.name,
    required this.balance,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
  });

  factory BalanceInfo.fromJson(Map<String, dynamic> json) {
    return BalanceInfo(
      name: json['name'] ?? '',
      balance: double.parse(json['balance']?.toString() ?? '0'),
      bankName: json['bank_name'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      bankAccountName: json['bank_account_name'] ?? '',
    );
  }
}
