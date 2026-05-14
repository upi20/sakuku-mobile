import 'package:equatable/equatable.dart';
import '../../../core/models/debt_trans_model.dart';

abstract class DebtTransState extends Equatable {
  const DebtTransState();
  @override
  List<Object?> get props => [];
}

class DebtTransInitial extends DebtTransState {
  const DebtTransInitial();
}

class DebtTransLoading extends DebtTransState {
  const DebtTransLoading();
}

class DebtTransLoaded extends DebtTransState {
  final List<DebtTransModel> transactions;
  final int debtId;
  const DebtTransLoaded({required this.transactions, required this.debtId});
  @override
  List<Object?> get props => [transactions, debtId];
}

class DebtTransSuccess extends DebtTransState {
  final String message;
  const DebtTransSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class DebtTransError extends DebtTransState {
  final String message;
  const DebtTransError(this.message);
  @override
  List<Object?> get props => [message];
}
