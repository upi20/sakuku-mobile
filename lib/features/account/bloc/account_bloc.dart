import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/local/account_repository.dart';
import '../../../core/models/account_model.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final IAccountRepository _repo;

  AccountBloc({IAccountRepository? repo})
      : _repo = repo ?? AccountRepository(),
        super(const AccountInitial()) {
    on<AccountLoad>(_onLoad);
    on<AccountCreate>(_onCreate);
    on<AccountUpdate>(_onUpdate);
    on<AccountDelete>(_onDelete);
    on<AccountToggleActive>(_onToggleActive);
  }

  Future<void> _onLoad(AccountLoad event, Emitter<AccountState> emit) async {
    emit(const AccountLoading());
    try {
      final accounts = await _repo.getAll(activeOnly: false);
      final balances = await _repo.getAllBalances();
      emit(AccountLoaded(accounts: accounts, balances: balances));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onCreate(
      AccountCreate event, Emitter<AccountState> emit) async {
    try {
      final newId = await _repo.create(event.account);
      // Buat entri History "Saldo Awal" jika > 0
      if (event.initialBalance > 0) {
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final db = await AppDatabase.instance.database;
        await db.insert('History', {
          'history_category_id': 8, // Saldo Awal
          'history_account_id': newId,
          'history_transfer_id': 0,
          'history_type': 1,
          'history_amount': event.initialBalance,
          'history_date': dateStr,
          'history_time': timeStr,
          'history_date_time': '$dateStr $timeStr',
          'history_note': 'Saldo Awal',
          'history_sign': '+',
          'history_debt_id': 0,
          'history_debt_trans_id': 0,
        });
      }
      emit(const AccountSuccess('Rekening berhasil ditambahkan'));
      add(const AccountLoad());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      AccountUpdate event, Emitter<AccountState> emit) async {
    try {
      await _repo.update(event.account);
      emit(const AccountSuccess('Rekening berhasil diperbarui'));
      add(const AccountLoad());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onDelete(
      AccountDelete event, Emitter<AccountState> emit) async {
    try {
      await _repo.delete(event.id);
      emit(const AccountSuccess('Rekening berhasil dihapus'));
      add(const AccountLoad());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onToggleActive(
      AccountToggleActive event, Emitter<AccountState> emit) async {
    try {
      final updated = AccountModel(
        id: event.account.id,
        name: event.account.name,
        icon: event.account.icon,
        color: event.account.color,
        active: event.account.active == 1 ? 0 : 1,
      );
      await _repo.update(updated);
      add(const AccountLoad());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
}
