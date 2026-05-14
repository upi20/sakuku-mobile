part of 'transfer_bloc.dart';

abstract class TransferState {}

class TransferLoading extends TransferState {}

class TransferReady extends TransferState {
  final List<AccountModel> accounts;
  final Map<int, double> balances;
  final AccountModel? srcAccount;
  final AccountModel? destAccount;
  final String amountText;
  final String feeText;
  final DateTime date;
  final TimeOfDay time;
  final int? editingId;

  TransferReady({
    required this.accounts,
    required this.balances,
    this.srcAccount,
    this.destAccount,
    required this.amountText,
    required this.feeText,
    required this.date,
    required this.time,
    this.editingId,
  });

  TransferReady copyWith({
    List<AccountModel>? accounts,
    Map<int, double>? balances,
    AccountModel? srcAccount,
    AccountModel? destAccount,
    String? amountText,
    String? feeText,
    DateTime? date,
    TimeOfDay? time,
    int? editingId,
  }) {
    return TransferReady(
      accounts: accounts ?? this.accounts,
      balances: balances ?? this.balances,
      srcAccount: srcAccount ?? this.srcAccount,
      destAccount: destAccount ?? this.destAccount,
      amountText: amountText ?? this.amountText,
      feeText: feeText ?? this.feeText,
      date: date ?? this.date,
      time: time ?? this.time,
      editingId: editingId ?? this.editingId,
    );
  }
}

class TransferSuccess extends TransferState {}

class TransferDeleteSuccess extends TransferState {}

class TransferError extends TransferState {
  final String message;
  TransferError(this.message);
}
