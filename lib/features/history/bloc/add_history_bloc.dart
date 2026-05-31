import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/ai_transaction_service.dart';
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
    on<AddHistoryAiRequested>(_onAiRequested);
  }

  Future<void> _onInit(AddHistoryInit event, Emitter<AddHistoryState> emit) async {
    emit(AddHistoryLoading());
    try {
      final seed = event.seed;
      final sign = seed?.sign ?? event.initialSign;
      final accounts = await _accountRepo.getAll();
      final categories = await _categoryRepo.getBySign(sign);
      final now = DateTime.now();

      CategoryModel? selectedCategory;
      AccountModel? selectedAccount;
      if (seed != null) {
        if (seed.categoryName != null && seed.categoryName!.isNotEmpty) {
          for (final c in categories) {
            if (c.name.toLowerCase() == seed.categoryName!.toLowerCase()) {
              selectedCategory = c;
              break;
            }
          }
        }
        if (seed.accountName != null && seed.accountName!.isNotEmpty) {
          for (final a in accounts) {
            if (a.name.toLowerCase() == seed.accountName!.toLowerCase()) {
              selectedAccount = a;
              break;
            }
          }
        }
      }

      emit(AddHistoryReady(
        accounts: accounts,
        categories: categories,
        sign: sign,
        amountText: seed?.amountText ?? '',
        note: seed?.note ?? '',
        date: now,
        time: TimeOfDay.fromDateTime(now),
        selectedCategory: selectedCategory,
        selectedAccount: selectedAccount,
        aiJustFilled: seed != null,
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

  Future<void> _onAiRequested(
    AddHistoryAiRequested event,
    Emitter<AddHistoryState> emit,
  ) async {
    if (state is! AddHistoryReady) return;
    final s = state as AddHistoryReady;

    emit(s.copyWith(isAiLoading: true));

    try {
      // Ambil semua kategori (bukan hanya yang difilter sign saat ini)
      // karena AI yang menentukan sign — pola sama seperti _onEditInit.
      final allCategories = await _categoryRepo.getAll();

      final result = await AiTransactionService.instance.parse(
        userInput: event.text,
        categories: allCategories,
        accounts: s.accounts, // sudah ada di state, tidak perlu query ulang
        allowTransfer: false,
      );
      // allowTransfer=false menjamin selalu transaction
      final tx = result as AiParsedTransaction;

      // Reload kategori sesuai sign yang ditentukan AI — pola sama seperti _onTypeChanged.
      final filteredCategories = await _categoryRepo.getBySign(tx.sign);

      // Cari object matching — case-insensitive, dengan fallback ke first.
      final category = filteredCategories.firstWhere(
        (c) => c.name.toLowerCase() == tx.categoryName.toLowerCase(),
        orElse: () => filteredCategories.first,
      );
      final account = s.accounts.firstWhere(
        (a) => a.name.toLowerCase() == tx.accountName.toLowerCase(),
        orElse: () => s.accounts.first,
      );

      emit(s.copyWith(
        sign: tx.sign,
        categories: filteredCategories,
        selectedCategory: category,
        selectedAccount: account,
        amountText: tx.amountText,
        note: tx.note,
        aiJustFilled: true,
        isAiLoading: false,
      ));
    } on Exception catch (e) {
      emit(s.copyWith(isAiLoading: false));
      emit(AddHistoryError(e.toString()));
      emit(s.copyWith(isAiLoading: false));
    }
  }
}
