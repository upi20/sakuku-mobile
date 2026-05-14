class DebtModel {
  final int? id;
  final int accountId;
  final String name;
  final double amount;
  final String note;
  final String startDateTime;
  final String endDateTime;
  final int type; // 1=debt (hutang), 2=loan (piutang)

  // Joined
  final String? accountName;
  final String? accountIcon;
  final String? accountColor;

  // Computed
  final double? paidAmount;

  const DebtModel({
    this.id,
    required this.accountId,
    required this.name,
    required this.amount,
    this.note = '',
    required this.startDateTime,
    this.endDateTime = '',
    required this.type,
    this.accountName,
    this.accountIcon,
    this.accountColor,
    this.paidAmount,
  });

  bool get isDebt => type == 1;
  bool get isLoan => type == 2;
  double get remainingAmount => amount - (paidAmount ?? 0);
  bool get isRelief => remainingAmount <= 0;

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['debt_id'] as int?,
      accountId: map['debt_account_id'] as int,
      name: map['debt_name'] as String,
      amount: (map['debt_amount'] as num).toDouble(),
      note: (map['debt_note'] as String?) ?? '',
      startDateTime: map['debt_start_date_time'] as String,
      endDateTime: (map['debt_end_date_time'] as String?) ?? '',
      type: map['debt_type'] as int,
      accountName: map['account_name'] as String?,
      accountIcon: map['account_icon'] as String?,
      accountColor: map['account_color'] as String?,
      paidAmount: map['paid_amount'] != null
          ? (map['paid_amount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'debt_id': id,
      'debt_account_id': accountId,
      'debt_name': name,
      'debt_amount': amount,
      'debt_note': note,
      'debt_start_date_time': startDateTime,
      'debt_end_date_time': endDateTime,
      'debt_type': type,
    };
  }

  DebtModel copyWith({
    int? id,
    int? accountId,
    String? name,
    double? amount,
    String? note,
    String? startDateTime,
    String? endDateTime,
    int? type,
  }) {
    return DebtModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      type: type ?? this.type,
    );
  }
}
