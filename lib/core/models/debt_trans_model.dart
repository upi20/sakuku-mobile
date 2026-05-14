class DebtTransModel {
  final int? id;
  final int debtId;
  final int accountId;
  final double amount;
  final String note;
  final String dateTime;
  final int type; // 1=payment, 2=addition

  // Joined
  final String? accountName;
  final String? debtName;

  const DebtTransModel({
    this.id,
    required this.debtId,
    required this.accountId,
    required this.amount,
    this.note = '',
    required this.dateTime,
    required this.type,
    this.accountName,
    this.debtName,
  });

  factory DebtTransModel.fromMap(Map<String, dynamic> map) {
    return DebtTransModel(
      id: map['debt_trans_id'] as int?,
      debtId: map['debt_trans_debt_id'] as int,
      accountId: map['debt_trans_account_id'] as int,
      amount: (map['debt_trans_amount'] as num).toDouble(),
      note: (map['debt_trans_note'] as String?) ?? '',
      dateTime: map['debt_trans_date_time'] as String,
      type: map['debt_trans_type'] as int,
      accountName: map['account_name'] as String?,
      debtName: map['debt_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'debt_trans_id': id,
      'debt_trans_debt_id': debtId,
      'debt_trans_account_id': accountId,
      'debt_trans_amount': amount,
      'debt_trans_note': note,
      'debt_trans_date_time': dateTime,
      'debt_trans_type': type,
    };
  }
}
