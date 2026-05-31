part of 'add_history_bloc.dart';

abstract class AddHistoryEvent {}

/// Optional seed values from AI quick-add to pre-fill the form.
class AddHistoryAiSeed {
  final String sign;
  final String amountText;
  final String note;
  final String? categoryName;
  final String? accountName;

  const AddHistoryAiSeed({
    required this.sign,
    required this.amountText,
    required this.note,
    this.categoryName,
    this.accountName,
  });
}

class AddHistoryInit extends AddHistoryEvent {
  final String initialSign; // '+' or '-'
  final AddHistoryAiSeed? seed;
  AddHistoryInit({this.initialSign = '-', this.seed});
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

/// Meminta AI untuk mem-parse teks kasual dan mengisi form secara otomatis.
class AddHistoryAiRequested extends AddHistoryEvent {
  final String text;
  AddHistoryAiRequested(this.text);
}
