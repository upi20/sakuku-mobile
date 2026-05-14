import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/history_model.dart';
import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/interfaces/i_category_repository.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';

part 'add_history_event.dart';
part 'add_history_state.dart';

class AddHistoryBloc extends Bloc<AddHistoryEvent, AddHistoryState> {
  final IHistoryRepository _historyRepo;
  final IAccountRepository _accountRepo;
  final ICategoryRepository _categoryRepo;

  AddHistoryBloc(
    this._historyRepo,
    this._accountRepo,
    this._categoryRepo,
  ) : super(AddHistoryLoading()) {
    on<AddHistoryInit>(_onInit);
    on<AddHistoryEditInit>(_onEditInit);
    on<AddHistoryTypeChanged>(_onTypeChanged);
    on<AddHistoryCategorySelected>(_onCategorySelected);
    on<AddHistoryAccountSelected>(_onAccountSelected);
    on<AddHistoryAmountChanged>(_onAmountChanged);
    on<AddHistoryNoteChanged>(_onNoteChanged);
    on<AddHistoryDateChanged>(_onDateChanged);
    on<AddHistoryTimeChanged>(_onTimeChanged);
    on<AddHistorySubmit>(_onSubmit);
  }

  Future<void> _onInit(AddHistoryInit event, Emitter<AddHistoryState> emit) async {
    emit(AddHistoryLoading());
    try {
      final accounts = await _accountRepo.getAll();
      final categories = await _categoryRepo.getBySign(event.initialSign);
      final now = DateTime.now();
      emit(AddHistoryReady(
        accounts: accounts,
        categories: categories,
        sign: event.initialSign,
        amountText: '',
        note: '',
        date: now,
        time: TimeOfDay.fromDateTime(now),
      ));
    } catch (e) {
      emit(AddHistoryError(e.toString()));
    }
  }

  Future<void> _onEditInit(AddHistoryEditInit event, Emitter<AddHistoryState> emit) async {
    emit(AddHistoryLoading());
    try {
      final existing = event.existing;
      final accounts = await _accountRepo.getAll();
      final categories = await _categoryRepo.getBySign(existing.sign);

      AccountModel? selectedAccount;
      CategoryModel? selectedCategory;

      for (final a in accounts) {
        if (a.id == existing.accountId) {
          selectedAccount = a;
          break;
        }
      }
      for (final c in categories) {
        if (c.id == existing.categoryId) {
          selectedCategory = c;
          break;
        }
      }

      final dateParts = existing.date.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      final timeParts = existing.time.split(':');
      final time = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      emit(AddHistoryReady(
        accounts: accounts,
        categories: categories,
        sign: existing.sign,
        selectedCategory: selectedCategory,
        selectedAccount: selectedAccount,
        amountText: existing.amount.toStringAsFixed(0),
        note: existing.note,
        date: date,
        time: time,
        editingId: existing.id,
      ));
    } catch (e) {
      emit(AddHistoryError(e.toString()));
    }
  }

  Future<void> _onTypeChanged(AddHistoryTypeChanged event, Emitter<AddHistoryState> emit) async {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    final categories = await _categoryRepo.getBySign(event.sign);
    emit(s.copyWith(sign: event.sign, categories: categories, clearCategory: true));
  }

  void _onCategorySelected(AddHistoryCategorySelected event, Emitter<AddHistoryState> emit) {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    emit(s.copyWith(selectedCategory: event.category));
  }

  void _onAccountSelected(AddHistoryAccountSelected event, Emitter<AddHistoryState> emit) {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    emit(s.copyWith(selectedAccount: event.account));
  }

  void _onAmountChanged(AddHistoryAmountChanged event, Emitter<AddHistoryState> emit) {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    emit(s.copyWith(amountText: event.value));
  }

  void _onNoteChanged(AddHistoryNoteChanged event, Emitter<AddHistoryState> emit) {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    emit(s.copyWith(note: event.value));
  }

  void _onDateChanged(AddHistoryDateChanged event, Emitter<AddHistoryState> emit) {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    emit(s.copyWith(date: event.date));
  }

  void _onTimeChanged(AddHistoryTimeChanged event, Emitter<AddHistoryState> emit) {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;
    emit(s.copyWith(time: event.time));
  }

  Future<void> _onSubmit(AddHistorySubmit event, Emitter<AddHistoryState> emit) async {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;

    if (s.selectedCategory == null || s.selectedAccount == null) return;
    final amount = double.tryParse(s.amountText);
    if (amount == null || amount <= 0) return;

    final dateStr =
        '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}:00';
    final dateTimeStr = '$dateStr $timeStr';

    final model = HistoryModel(
      id: s.editingId,
      categoryId: s.selectedCategory!.id!,
      accountId: s.selectedAccount!.id!,
      type: 1,
      amount: amount,
      date: dateStr,
      time: timeStr,
      dateTime: dateTimeStr,
      note: s.note,
      sign: s.sign,
    );

    try {
      if (s.editingId != null) {
        await _historyRepo.update(model);
      } else {
        await _historyRepo.create(model);
      }
      emit(AddHistorySuccess());
    } catch (e) {
      emit(AddHistoryError(e.toString()));
    }
  }
}
