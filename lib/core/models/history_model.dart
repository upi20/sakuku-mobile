class HistoryModel {
  final int? id;
  final int categoryId;
  final int accountId;
  final int transferId;
  final int type; // 1=income, 2=expense, 3=transfer
  final double amount;
  final String date;
  final String time;
  final String dateTime;
  final String note;
  final String sign; // '+' or '-'
  final int debtId;
  final int debtTransId;

  // Joined fields (not stored in DB)
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? accountName;
  final String? accountIcon;
  final String? accountColor;

  const HistoryModel({
    this.id,
    required this.categoryId,
    required this.accountId,
    this.transferId = 0,
    required this.type,
    required this.amount,
    required this.date,
    required this.time,
    required this.dateTime,
    this.note = '',
    required this.sign,
    this.debtId = 0,
    this.debtTransId = 0,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.accountName,
    this.accountIcon,
    this.accountColor,
  });

  bool get isIncome => sign == '+';
  bool get isExpense => sign == '-';
  bool get isTransfer => type == 3;

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['history_id'] as int?,
      categoryId: map['history_category_id'] as int,
      accountId: map['history_account_id'] as int,
      transferId: (map['history_transfer_id'] as int?) ?? 0,
      type: map['history_type'] as int,
      amount: (map['history_amount'] as num).toDouble(),
      date: map['history_date'] as String,
      time: map['history_time'] as String,
      dateTime: map['history_date_time'] as String,
      note: (map['history_note'] as String?) ?? '',
      sign: map['history_sign'] as String,
      debtId: (map['history_debt_id'] as int?) ?? 0,
      debtTransId: (map['history_debt_trans_id'] as int?) ?? 0,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as String?,
      accountName: map['account_name'] as String?,
      accountIcon: map['account_icon'] as String?,
      accountColor: map['account_color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'history_id': id,
      'history_category_id': categoryId,
      'history_account_id': accountId,
      'history_transfer_id': transferId,
      'history_type': type,
      'history_amount': amount,
      'history_date': date,
      'history_time': time,
      'history_date_time': dateTime,
      'history_note': note,
      'history_sign': sign,
      'history_debt_id': debtId,
      'history_debt_trans_id': debtTransId,
    };
  }

  HistoryModel copyWith({
    int? id,
    int? categoryId,
    int? accountId,
    int? transferId,
    int? type,
    double? amount,
    String? date,
    String? time,
    String? dateTime,
    String? note,
    String? sign,
    int? debtId,
    int? debtTransId,
  }) {
    return HistoryModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transferId: transferId ?? this.transferId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      sign: sign ?? this.sign,
      debtId: debtId ?? this.debtId,
      debtTransId: debtTransId ?? this.debtTransId,
    );
  }
}
