import 'package:equatable/equatable.dart';
import '../../../core/models/account_model.dart';

abstract class AccountState extends Equatable {
  const AccountState();
  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final List<AccountModel> accounts;
  final Map<int, double> balances;

  const AccountLoaded({required this.accounts, required this.balances});

  double balanceOf(int accountId) => balances[accountId] ?? 0.0;

  double get totalBalance =>
      balances.values.fold(0.0, (sum, b) => sum + b);

  @override
  List<Object?> get props => [accounts, balances];
}

class AccountSuccess extends AccountState {
  final String message;
  const AccountSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);
  @override
  List<Object?> get props => [message];
}
