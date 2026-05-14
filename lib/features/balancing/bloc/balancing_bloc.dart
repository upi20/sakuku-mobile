import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/database/daos/account_dao.dart';
import '../../../core/database/daos/history_dao.dart';
import '../../../core/database/daos/history_transfer_dao.dart';
import '../../../core/models/history_model.dart';
import '../../../core/models/history_transfer_model.dart';
import '../model/balancing_item.dart';
import '../model/bulk_transaction_entry.dart';

part 'balancing_event.dart';
part 'balancing_state.dart';

// Category IDs yang digunakan untuk transfer (konsisten dengan TransferBloc)
const int _kCategorySrcTransfer = 1;  // Kirim Saldo (-)
const int _kCategoryDestTransfer = 2; // Terima Saldo (+)

class BalancingBloc extends Bloc<BalancingEvent, BalancingState> {
  final AccountDao _accountDao;
  final HistoryDao _historyDao;
  final HistoryTransferDao _transferDao;

  BalancingBloc({
    AccountDao? accountDao,
    HistoryDao? historyDao,
    HistoryTransferDao? transferDao,
  })  : _accountDao = accountDao ?? AccountDao(),
        _historyDao = historyDao ?? HistoryDao(),
        _transferDao = transferDao ?? HistoryTransferDao(),
        super(const BalancingInitial()) {
    on<BalancingLoad>(_onLoad);
    on<BalancingRealBalanceChanged>(_onRealBalanceChanged);
    on<BalancingDenominationUsed>(_onDenominationUsed);
    on<BalancingAddBulkEntry>(_onAddBulkEntry);
    on<BalancingRemoveBulkEntry>(_onRemoveBulkEntry);
    on<BalancingUpdateBulkEntry>(_onUpdateBulkEntry);
    on<BalancingSelectAccount>(_onSelectAccount);
    on<BalancingSave>(_onSave);
  }

  // ── Helpers ──────────────────────────────────────────────────

  BalancingLoaded? get _loaded {
    final s = state;
    if (s is BalancingLoaded) return s;
    return null;
  }

  String _dateStr(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  String _timeStr(DateTime dt) => DateFormat('HH:mm:ss').format(dt);
  String _dateTimeStr(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  // ── Handlers ─────────────────────────────────────────────────

  Future<void> _onLoad(
    BalancingLoad event,
    Emitter<BalancingState> emit,
  ) async {
    emit(const BalancingLoading());
    try {
      final accounts = await _accountDao.getAll(activeOnly: true);
      final balances = await _accountDao.getAllBalances();

      final items = accounts.map((acc) {
        final appBal = balances[acc.id] ?? 0.0;
        return BalancingItem(account: acc, appBalance: appBal);
      }).toList();

      emit(BalancingLoaded(items: items));
    } catch (e) {
      emit(BalancingError('Gagal memuat data rekening: $e'));
    }
  }

  void _onRealBalanceChanged(
    BalancingRealBalanceChanged event,
    Emitter<BalancingState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;

    final updated = loaded.items.map((item) {
      if (item.account.id == event.accountId) {
        return item.copyWith(realBalance: event.amount);
      }
      return item;
    }).toList();

    emit(loaded.copyWith(items: updated));
  }

  void _onDenominationUsed(
    BalancingDenominationUsed event,
    Emitter<BalancingState> emit,
  ) {
    _onRealBalanceChanged(
      BalancingRealBalanceChanged(event.accountId, event.total),
      emit,
    );
  }

  void _onAddBulkEntry(
    BalancingAddBulkEntry event,
    Emitter<BalancingState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;

    emit(loaded.copyWith(
      bulkEntries: [...loaded.bulkEntries, const BulkTransactionEntry()],
    ));
  }

  void _onRemoveBulkEntry(
    BalancingRemoveBulkEntry event,
    Emitter<BalancingState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    if (event.index < 0 || event.index >= loaded.bulkEntries.length) return;

    final updated = List<BulkTransactionEntry>.from(loaded.bulkEntries)
      ..removeAt(event.index);
    emit(loaded.copyWith(bulkEntries: updated));
  }

  void _onUpdateBulkEntry(
    BalancingUpdateBulkEntry event,
    Emitter<BalancingState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    if (event.index < 0 || event.index >= loaded.bulkEntries.length) return;

    final updated = List<BulkTransactionEntry>.from(loaded.bulkEntries);
    updated[event.index] = event.entry;
    emit(loaded.copyWith(bulkEntries: updated));
  }

  void _onSelectAccount(
    BalancingSelectAccount event,
    Emitter<BalancingState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(balancingAccountId: event.accountId));
  }

  Future<void> _onSave(
    BalancingSave event,
    Emitter<BalancingState> emit,
  ) async {
    final loaded = _loaded;
    if (loaded == null) return;
    if (loaded.balancingAccountId == null) return;

    emit(const BalancingSaving());

    try {
      final now = DateTime.now();
      final dateStr = _dateStr(now);
      final timeStr = _timeStr(now);
      final dateTimeStr = _dateTimeStr(now);
      final balancingId = loaded.balancingAccountId!;

      // ── 1. Transfer antar rekening ────────────────────────────
      for (final item in loaded.transferItems) {
        final accountId = item.account.id!;
        final selisih = item.selisih;

        int srcId;
        int destId;
        double amount;
        String srcName;
        String destName;

        if (selisih < 0) {
          // App > Real → rekening ini kirim ke balancing
          srcId = accountId;
          destId = balancingId;
          amount = selisih.abs();
          srcName = item.account.name;
          destName = _balancingName(loaded, balancingId);
        } else {
          // Real > App → balancing kirim ke rekening ini
          srcId = balancingId;
          destId = accountId;
          amount = selisih;
          srcName = _balancingName(loaded, balancingId);
          destName = item.account.name;
        }

        // Insert HistoryTransfer
        final transfer = HistoryTransferModel(
          srcAccountId: srcId,
          destAccountId: destId,
          amount: amount,
          date: dateStr,
          time: timeStr,
          datetime: dateTimeStr,
        );
        final transferId = await _transferDao.insert(transfer);

        // History: keluar dari src
        await _historyDao.insert(HistoryModel(
          categoryId: _kCategorySrcTransfer,
          accountId: srcId,
          transferId: transferId,
          type: 2,
          amount: amount,
          date: dateStr,
          time: timeStr,
          dateTime: dateTimeStr,
          note: 'Ke $destName',
          sign: '-',
        ));

        // History: masuk ke dest
        await _historyDao.insert(HistoryModel(
          categoryId: _kCategoryDestTransfer,
          accountId: destId,
          transferId: transferId,
          type: 2,
          amount: amount,
          date: dateStr,
          time: timeStr,
          dateTime: dateTimeStr,
          note: 'Dari $srcName',
          sign: '+',
        ));
      }

      // ── 2. Transaksi bulk (pengeluaran dari rekening balancing) ──
      for (final entry in loaded.bulkEntries) {
        if (entry.amount <= 0 || entry.categoryId == 0) continue;

        await _historyDao.insert(HistoryModel(
          categoryId: entry.categoryId,
          accountId: balancingId,
          type: 2,
          amount: entry.amount,
          date: dateStr,
          time: timeStr,
          dateTime: dateTimeStr,
          note: entry.note,
          sign: '-',
        ));
      }

      emit(const BalancingSaveSuccess());
    } catch (e) {
      emit(BalancingError('Gagal menyimpan: $e'));
    }
  }

  String _balancingName(BalancingLoaded loaded, int balancingId) {
    try {
      return loaded.items
          .firstWhere((i) => i.account.id == balancingId)
          .account
          .name;
    } catch (_) {
      return 'Balancing';
    }
  }
}
