part of 'transfer_bloc.dart';

abstract class TransferEvent {}

class TransferInit extends TransferEvent {}

class TransferEditInit extends TransferEvent {
  final int transferId;
  TransferEditInit(this.transferId);
}

class TransferSrcAccountSelected extends TransferEvent {
  final AccountModel account;
  TransferSrcAccountSelected(this.account);
}

class TransferDestAccountSelected extends TransferEvent {
  final AccountModel account;
  TransferDestAccountSelected(this.account);
}

class TransferAmountChanged extends TransferEvent {
  final String value;
  TransferAmountChanged(this.value);
}

class TransferFeeChanged extends TransferEvent {
  final String value;
  TransferFeeChanged(this.value);
}

class TransferDateChanged extends TransferEvent {
  final DateTime date;
  TransferDateChanged(this.date);
}

class TransferTimeChanged extends TransferEvent {
  final TimeOfDay time;
  TransferTimeChanged(this.time);
}

class TransferSubmit extends TransferEvent {}

class TransferUpdate extends TransferEvent {}

class TransferDeleteRequested extends TransferEvent {
  final int transferId;
  TransferDeleteRequested(this.transferId);
}
