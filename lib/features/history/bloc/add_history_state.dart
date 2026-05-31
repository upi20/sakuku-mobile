part of 'add_history_bloc.dart';

abstract class AddHistoryState {}

class AddHistoryLoading extends AddHistoryState {}

class AddHistoryReady extends AddHistoryState {
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final String sign; // '+' or '-'
  final CategoryModel? selectedCategory;
  final AccountModel? selectedAccount;
  final String amountText;
  final String note;
  final DateTime date;
  final TimeOfDay time;
  final int? editingId;
  final bool isAiLoading;
  /// true hanya pada emit terakhir dari _onAiRequested — untuk trigger TTS sekali.
  final bool aiJustFilled;

  AddHistoryReady({
    required this.accounts,
    required this.categories,
    required this.sign,
    this.selectedCategory,
    this.selectedAccount,
    required this.amountText,
    required this.note,
    required this.date,
    required this.time,
    this.editingId,
    this.isAiLoading = false,
    this.aiJustFilled = false,
  });

  AddHistoryReady copyWith({
    List<AccountModel>? accounts,
    List<CategoryModel>? categories,
    String? sign,
    CategoryModel? selectedCategory,
    bool clearCategory = false,
    AccountModel? selectedAccount,
    String? amountText,
    String? note,
    DateTime? date,
    TimeOfDay? time,
    int? editingId,
    bool? isAiLoading,
    bool aiJustFilled = false, // selalu reset ke false kecuali AI yang set
  }) {
    return AddHistoryReady(
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      sign: sign ?? this.sign,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedAccount: selectedAccount ?? this.selectedAccount,
      amountText: amountText ?? this.amountText,
      note: note ?? this.note,
      date: date ?? this.date,
      time: time ?? this.time,
      editingId: editingId ?? this.editingId,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      aiJustFilled: aiJustFilled,
    );
  }
}

class AddHistorySuccess extends AddHistoryState {}

class AddHistoryError extends AddHistoryState {
  final String message;
  AddHistoryError(this.message);
}
