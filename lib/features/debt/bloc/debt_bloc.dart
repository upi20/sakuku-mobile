import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/interfaces/i_debt_repository.dart';
import '../../../core/repositories/local/debt_repository.dart';
import 'debt_event.dart';
import 'debt_state.dart';

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final IDebtRepository _repo;
  int _currentType = 1;

  DebtBloc({IDebtRepository? repo})
      : _repo = repo ?? DebtRepository(),
        super(const DebtInitial()) {
    on<DebtLoad>(_onLoad);
    on<DebtCreate>(_onCreate);
    on<DebtUpdate>(_onUpdate);
    on<DebtDelete>(_onDelete);
    on<DebtLoadDetail>(_onLoadDetail);
  }

  Future<void> _onLoad(DebtLoad event, Emitter<DebtState> emit) async {
    _currentType = event.type;
    emit(const DebtLoading());
    try {
      final unpaid = await _repo.getAll(type: event.type, isRelief: false);
      final paid = await _repo.getAll(type: event.type, isRelief: true);
      emit(DebtLoaded(unpaid: unpaid, paid: paid, type: event.type));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onCreate(DebtCreate event, Emitter<DebtState> emit) async {
    try {
      await _repo.createDebt(event.debt);
      emit(const DebtSuccess('Berhasil ditambahkan'));
      add(DebtLoad(_currentType));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onUpdate(DebtUpdate event, Emitter<DebtState> emit) async {
    try {
      await _repo.updateDebt(event.debt);
      emit(const DebtSuccess('Berhasil diperbarui'));
      add(DebtLoad(_currentType));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onDelete(DebtDelete event, Emitter<DebtState> emit) async {
    try {
      await _repo.deleteDebt(event.id);
      emit(const DebtSuccess('Berhasil dihapus'));
      add(DebtLoad(_currentType));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onLoadDetail(
      DebtLoadDetail event, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      final debt = await _repo.getById(event.id);
      if (debt != null) {
        emit(DebtDetailLoaded(debt));
      } else {
        emit(const DebtError('Data tidak ditemukan'));
      }
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }
}
