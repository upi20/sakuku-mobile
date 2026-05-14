import 'package:equatable/equatable.dart';
import '../../../core/models/debt_trans_model.dart';

abstract class DebtTransEvent extends Equatable {
  const DebtTransEvent();
  @override
  List<Object?> get props => [];
}

class DebtTransLoad extends DebtTransEvent {
  final int debtId;
  const DebtTransLoad(this.debtId);
  @override
  List<Object?> get props => [debtId];
}

class DebtTransCreate extends DebtTransEvent {
  final DebtTransModel trans;
  const DebtTransCreate(this.trans);
  @override
  List<Object?> get props => [trans];
}

class DebtTransUpdate extends DebtTransEvent {
  final DebtTransModel trans;
  const DebtTransUpdate(this.trans);
  @override
  List<Object?> get props => [trans];
}

class DebtTransDelete extends DebtTransEvent {
  final int id;
  final int debtId;
  const DebtTransDelete({required this.id, required this.debtId});
  @override
  List<Object?> get props => [id, debtId];
}
