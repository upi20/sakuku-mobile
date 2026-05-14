class HistoryTransferModel {
  final int? id;
  final int srcAccountId;
  final int destAccountId;
  final double amount;
  final String date;
  final String time;
  final String datetime;

  // Joined
  final String? srcAccountName;
  final String? srcAccountIcon;
  final String? srcAccountColor;
  final String? destAccountName;
  final String? destAccountIcon;
  final String? destAccountColor;

  const HistoryTransferModel({
    this.id,
    required this.srcAccountId,
    required this.destAccountId,
    required this.amount,
    required this.date,
    required this.time,
    required this.datetime,
    this.srcAccountName,
    this.srcAccountIcon,
    this.srcAccountColor,
    this.destAccountName,
    this.destAccountIcon,
    this.destAccountColor,
  });

  factory HistoryTransferModel.fromMap(Map<String, dynamic> map) {
    return HistoryTransferModel(
      id: map['transfer_id'] as int?,
      srcAccountId: map['transfer_src_account_id'] as int,
      destAccountId: map['transfer_dest_account_id'] as int,
      amount: (map['transfer_amount'] as num).toDouble(),
      date: map['transfer_date'] as String,
      time: map['transfer_time'] as String,
      datetime: map['transfer_datetime'] as String,
      srcAccountName: map['src_account_name'] as String?,
      srcAccountIcon: map['src_account_icon'] as String?,
      srcAccountColor: map['src_account_color'] as String?,
      destAccountName: map['dest_account_name'] as String?,
      destAccountIcon: map['dest_account_icon'] as String?,
      destAccountColor: map['dest_account_color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'transfer_id': id,
      'transfer_src_account_id': srcAccountId,
      'transfer_dest_account_id': destAccountId,
      'transfer_amount': amount,
      'transfer_date': date,
      'transfer_time': time,
      'transfer_datetime': datetime,
    };
  }
}
