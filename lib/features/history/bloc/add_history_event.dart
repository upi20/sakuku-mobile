part of 'add_history_bloc.dart';

abstract class AddHistoryEvent {}

class AddHistoryInit extends AddHistoryEvent {
  final String initialSign; // '+' or '-'
  AddHistoryInit({this.initialSign = '-'});
}

class AddHistoryEditInit extends AddHistoryEvent {
  final HistoryModel existing;
  AddHistoryEditInit(this.existing);
}

class AddHistoryTypeChanged extends AddHistoryEvent {
  final String sign; // '+' or '-'
  AddHistoryTypeChanged(this.sign);
}

class AddHistoryCategorySelected extends AddHistoryEvent {
  final CategoryModel category;
  AddHistoryCategorySelected(this.category);
}

class AddHistoryAccountSelected extends AddHistoryEvent {
  final AccountModel account;
  AddHistoryAccountSelected(this.account);
}

class AddHistoryAmountChanged extends AddHistoryEvent {
  final String value;
  AddHistoryAmountChanged(this.value);
}

class AddHistoryNoteChanged extends AddHistoryEvent {
  final String value;
  AddHistoryNoteChanged(this.value);
}

class AddHistoryDateChanged extends AddHistoryEvent {
  final DateTime date;
  AddHistoryDateChanged(this.date);
}

class AddHistoryTimeChanged extends AddHistoryEvent {
  final TimeOfDay time;
  AddHistoryTimeChanged(this.time);
}

class AddHistorySubmit extends AddHistoryEvent {}
