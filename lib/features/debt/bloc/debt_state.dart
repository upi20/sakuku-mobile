import 'package:equatable/equatable.dart';
import '../../../core/models/debt_model.dart';

abstract class DebtState extends Equatable {
  const DebtState();
  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {
  const DebtInitial();
}

class DebtLoading extends DebtState {
  const DebtLoading();
}

class DebtLoaded extends DebtState {
  final List<DebtModel> unpaid; // belum lunas
  final List<DebtModel> paid;   // lunas
  final int type; // 1=hutang, 2=piutang
  const DebtLoaded({required this.unpaid, required this.paid, required this.type});
  @override
  List<Object?> get props => [unpaid, paid, type];
}

class DebtDetailLoaded extends DebtState {
  final DebtModel debt;
  const DebtDetailLoaded(this.debt);
  @override
  List<Object?> get props => [debt];
}

class DebtSuccess extends DebtState {
  final String message;
  const DebtSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class DebtError extends DebtState {
  final String message;
  const DebtError(this.message);
  @override
  List<Object?> get props => [message];
}
