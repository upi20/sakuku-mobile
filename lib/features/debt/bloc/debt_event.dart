import 'package:equatable/equatable.dart';
import '../../../core/models/debt_model.dart';

abstract class DebtEvent extends Equatable {
  const DebtEvent();
  @override
  List<Object?> get props => [];
}

class DebtLoad extends DebtEvent {
  final int type; // 1=hutang, 2=piutang
  const DebtLoad(this.type);
  @override
  List<Object?> get props => [type];
}

class DebtCreate extends DebtEvent {
  final DebtModel debt;
  const DebtCreate(this.debt);
  @override
  List<Object?> get props => [debt];
}

class DebtUpdate extends DebtEvent {
  final DebtModel debt;
  const DebtUpdate(this.debt);
  @override
  List<Object?> get props => [debt];
}

class DebtDelete extends DebtEvent {
  final int id;
  const DebtDelete(this.id);
  @override
  List<Object?> get props => [id];
}

class DebtLoadDetail extends DebtEvent {
  final int id;
  const DebtLoadDetail(this.id);
  @override
  List<Object?> get props => [id];
}
