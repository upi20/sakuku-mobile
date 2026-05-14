import 'package:equatable/equatable.dart';
import '../../../core/models/account_model.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();
  @override
  List<Object?> get props => [];
}

class AccountLoad extends AccountEvent {
  const AccountLoad();
}

class AccountCreate extends AccountEvent {
  final AccountModel account;
  final double initialBalance;
  const AccountCreate(this.account, {this.initialBalance = 0.0});
  @override
  List<Object?> get props => [account, initialBalance];
}

class AccountUpdate extends AccountEvent {
  final AccountModel account;
  const AccountUpdate(this.account);
  @override
  List<Object?> get props => [account];
}

class AccountDelete extends AccountEvent {
  final int id;
  const AccountDelete(this.id);
  @override
  List<Object?> get props => [id];
}

class AccountToggleActive extends AccountEvent {
  final AccountModel account;
  const AccountToggleActive(this.account);
  @override
  List<Object?> get props => [account];
}
