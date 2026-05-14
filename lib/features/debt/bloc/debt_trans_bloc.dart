import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/interfaces/i_debt_repository.dart';
import '../../../core/repositories/local/debt_repository.dart';
import 'debt_trans_event.dart';
import 'debt_trans_state.dart';

class DebtTransBloc extends Bloc<DebtTransEvent, DebtTransState> {
  final IDebtRepository _repo;

  DebtTransBloc({IDebtRepository? repo})
      : _repo = repo ?? DebtRepository(),
        super(const DebtTransInitial()) {
    on<DebtTransLoad>(_onLoad);
    on<DebtTransCreate>(_onCreate);
    on<DebtTransUpdate>(_onUpdate);
    on<DebtTransDelete>(_onDelete);
  }

  Future<void> _onLoad(DebtTransLoad event, Emitter<DebtTransState> emit) async {
    emit(const DebtTransLoading());
    try {
      final list = await _repo.getTransactions(event.debtId);
      emit(DebtTransLoaded(transactions: list, debtId: event.debtId));
    } catch (e) {
      emit(DebtTransError(e.toString()));
    }
  }

  Future<void> _onCreate(DebtTransCreate event, Emitter<DebtTransState> emit) async {
    try {
      await _repo.createTransaction(event.trans);
      emit(const DebtTransSuccess('Transaksi berhasil ditambahkan'));
      add(DebtTransLoad(event.trans.debtId));
    } catch (e) {
      emit(DebtTransError(e.toString()));
    }
  }

  Future<void> _onUpdate(DebtTransUpdate event, Emitter<DebtTransState> emit) async {
    try {
      await _repo.updateTransaction(event.trans);
      emit(const DebtTransSuccess('Transaksi berhasil diperbarui'));
      add(DebtTransLoad(event.trans.debtId));
    } catch (e) {
      emit(DebtTransError(e.toString()));
    }
  }

  Future<void> _onDelete(DebtTransDelete event, Emitter<DebtTransState> emit) async {
    try {
      await _repo.deleteTransaction(event.id);
      emit(const DebtTransSuccess('Transaksi berhasil dihapus'));
      add(DebtTransLoad(event.debtId));
    } catch (e) {
      emit(DebtTransError(e.toString()));
    }
  }
}
