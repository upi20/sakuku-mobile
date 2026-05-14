import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/daos/history_transfer_dao.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/history_model.dart';
import '../../../core/models/history_transfer_model.dart';
import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';

part 'transfer_event.dart';
part 'transfer_state.dart';

// Fixed system category IDs from DB
const int _kCategorySrcTransfer = 1;   // Kirim Saldo (-)
const int _kCategoryDestTransfer = 2;  // Terima Saldo (+)
const int _kCategoryTransferFee = 3;   // Biaya Admin (-)

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final IAccountRepository _accountRepo;
  final IHistoryRepository _historyRepo;
  final HistoryTransferDao _transferDao;

  TransferBloc(
    this._accountRepo,
    this._historyRepo,
    this._transferDao,
  ) : super(TransferLoading()) {
    on<TransferInit>(_onInit);
    on<TransferEditInit>(_onEditInit);
    on<TransferSrcAccountSelected>(_onSrcSelected);
    on<TransferDestAccountSelected>(_onDestSelected);
    on<TransferAmountChanged>(_onAmountChanged);
    on<TransferFeeChanged>(_onFeeChanged);
    on<TransferDateChanged>(_onDateChanged);
    on<TransferTimeChanged>(_onTimeChanged);
    on<TransferSubmit>(_onSubmit);
    on<TransferUpdate>(_onUpdate);
    on<TransferDeleteRequested>(_onDelete);
  }

  Future<void> _onInit(TransferInit event, Emitter<TransferState> emit) async {
    emit(TransferLoading());
    try {
      final accounts = await _accountRepo.getAll();
      final balances = await _accountRepo.getAllBalances();
      final now = DateTime.now();
      emit(TransferReady(
        accounts: accounts,
        balances: balances,
        amountText: '',
        feeText: '',
        date: now,
        time: TimeOfDay.fromDateTime(now),
      ));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  void _onSrcSelected(TransferSrcAccountSelected event, Emitter<TransferState> emit) {
    if (state is! TransferReady) return;
    emit((state as TransferReady).copyWith(srcAccount: event.account));
  }

  void _onDestSelected(TransferDestAccountSelected event, Emitter<TransferState> emit) {
    if (state is! TransferReady) return;
    emit((state as TransferReady).copyWith(destAccount: event.account));
  }

  void _onAmountChanged(TransferAmountChanged event, Emitter<TransferState> emit) {
    if (state is! TransferReady) return;
    emit((state as TransferReady).copyWith(amountText: event.value));
  }

  void _onFeeChanged(TransferFeeChanged event, Emitter<TransferState> emit) {
    if (state is! TransferReady) return;
    emit((state as TransferReady).copyWith(feeText: event.value));
  }

  void _onDateChanged(TransferDateChanged event, Emitter<TransferState> emit) {
    if (state is! TransferReady) return;
    emit((state as TransferReady).copyWith(date: event.date));
  }

  void _onTimeChanged(TransferTimeChanged event, Emitter<TransferState> emit) {
    if (state is! TransferReady) return;
    emit((state as TransferReady).copyWith(time: event.time));
  }

  Future<void> _onSubmit(TransferSubmit event, Emitter<TransferState> emit) async {
    if (state is! TransferReady) return;
    final s = state as TransferReady;
    if (s.srcAccount == null || s.destAccount == null) return;

    final amount = double.tryParse(s.amountText);
    if (amount == null || amount <= 0) return;

    final fee = double.tryParse(s.feeText) ?? 0;
    final dateStr =
        '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}:00';
    final dateTimeStr = '$dateStr $timeStr';

    try {
      // 1. Insert HistoryTransfer record
      final transfer = HistoryTransferModel(
        srcAccountId: s.srcAccount!.id!,
        destAccountId: s.destAccount!.id!,
        amount: amount,
        date: dateStr,
        time: timeStr,
        datetime: dateTimeStr,
      );
      final transferId = await _transferDao.insert(transfer);

      // 2. History for src (expense)
      await _historyRepo.create(HistoryModel(
        categoryId: _kCategorySrcTransfer,
        accountId: s.srcAccount!.id!,
        transferId: transferId,
        type: 2,
        amount: amount,
        date: dateStr,
        time: timeStr,
        dateTime: dateTimeStr,
        note: 'Ke ${s.destAccount!.name}',
        sign: '-',
      ));

      // 3. History for dest (income)
      await _historyRepo.create(HistoryModel(
        categoryId: _kCategoryDestTransfer,
        accountId: s.destAccount!.id!,
        transferId: transferId,
        type: 2,
        amount: amount,
        date: dateStr,
        time: timeStr,
        dateTime: dateTimeStr,
        note: 'Dari ${s.srcAccount!.name}',
        sign: '+',
      ));

      // 4. Fee record (if any)
      if (fee > 0) {
        await _historyRepo.create(HistoryModel(
          categoryId: _kCategoryTransferFee,
          accountId: s.srcAccount!.id!,
          transferId: transferId,
          type: 4,
          amount: fee,
          date: dateStr,
          time: timeStr,
          dateTime: dateTimeStr,
          note: 'Biaya transfer',
          sign: '-',
        ));
      }

      emit(TransferSuccess());
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onDelete(TransferDeleteRequested event, Emitter<TransferState> emit) async {
    try {
      await _historyRepo.deleteByTransferId(event.transferId);
      await _transferDao.delete(event.transferId);
      emit(TransferDeleteSuccess());
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onEditInit(TransferEditInit event, Emitter<TransferState> emit) async {
    emit(TransferLoading());
    try {
      final accounts = await _accountRepo.getAll();
      final balances = await _accountRepo.getAllBalances();
      final transfer = await _transferDao.getById(event.transferId);
      if (transfer == null) {
        emit(TransferError('Transfer tidak ditemukan'));
        return;
      }
      final feeHistory = await _historyRepo.getFeeByTransferId(event.transferId);
      final feeText = feeHistory != null
          ? feeHistory.amount.toStringAsFixed(0)
          : '';

      final srcAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a?.id == transfer.srcAccountId,
        orElse: () => null,
      );
      final destAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a?.id == transfer.destAccountId,
        orElse: () => null,
      );

      final date = DateTime.parse(transfer.date);
      final timeParts = transfer.time.split(':');
      final time = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      emit(TransferReady(
        accounts: accounts,
        balances: balances,
        srcAccount: srcAccount,
        destAccount: destAccount,
        amountText: transfer.amount.toStringAsFixed(0),
        feeText: feeText,
        date: date,
        time: time,
        editingId: event.transferId,
      ));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onUpdate(TransferUpdate event, Emitter<TransferState> emit) async {
    if (state is! TransferReady) return;
    final s = state as TransferReady;
    if (s.editingId == null || s.srcAccount == null || s.destAccount == null) return;

    final amount = double.tryParse(s.amountText);
    if (amount == null || amount <= 0) return;
    final fee = double.tryParse(s.feeText) ?? 0;

    final dateStr =
        '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}:00';
    final dateTimeStr = '\$dateStr \$timeStr';

    try {
      await _transferDao.update(HistoryTransferModel(
        id: s.editingId,
        srcAccountId: s.srcAccount!.id!,
        destAccountId: s.destAccount!.id!,
        amount: amount,
        date: dateStr,
        time: timeStr,
        datetime: dateTimeStr,
      ));

      await _historyRepo.deleteByTransferId(s.editingId!);

      await _historyRepo.create(HistoryModel(
        categoryId: _kCategorySrcTransfer,
        accountId: s.srcAccount!.id!,
        transferId: s.editingId!,
        type: 2,
        amount: amount,
        date: dateStr,
        time: timeStr,
        dateTime: dateTimeStr,
        note: 'Ke \${s.destAccount!.name}',
        sign: '-',
      ));

      await _historyRepo.create(HistoryModel(
        categoryId: _kCategoryDestTransfer,
        accountId: s.destAccount!.id!,
        transferId: s.editingId!,
        type: 2,
        amount: amount,
        date: dateStr,
        time: timeStr,
        dateTime: dateTimeStr,
        note: 'Dari \${s.srcAccount!.name}',
        sign: '+',
      ));

      if (fee > 0) {
        await _historyRepo.create(HistoryModel(
          categoryId: _kCategoryTransferFee,
          accountId: s.srcAccount!.id!,
          transferId: s.editingId!,
          type: 4,
          amount: fee,
          date: dateStr,
          time: timeStr,
          dateTime: dateTimeStr,
          note: 'Biaya transfer',
          sign: '-',
        ));
      }

      emit(TransferSuccess());
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }
}
