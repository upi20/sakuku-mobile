class BulkTransactionEntry {
  final String note;
  final double amount;
  final int categoryId;
  final String categoryName;

  const BulkTransactionEntry({
    this.note = '',
    this.amount = 0,
    this.categoryId = 0,
    this.categoryName = '',
  });

  BulkTransactionEntry copyWith({
    String? note,
    double? amount,
    int? categoryId,
    String? categoryName,
  }) {
    return BulkTransactionEntry(
      note: note ?? this.note,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
