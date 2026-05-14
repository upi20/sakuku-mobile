import 'package:equatable/equatable.dart';

abstract class PinState extends Equatable {
  const PinState();
  @override
  List<Object?> get props => [];
}

class PinInitial extends PinState {
  const PinInitial();
}

class PinLoading extends PinState {
  const PinLoading();
}

/// Status awal setelah load: apakah PIN aktif, apakah sudah ada PIN tersimpan
class PinLoaded extends PinState {
  final bool isEnabled;
  final bool hasPin;
  const PinLoaded({required this.isEnabled, required this.hasPin});
  @override
  List<Object?> get props => [isEnabled, hasPin];
}

/// PIN check berhasil
class PinCheckSuccess extends PinState {
  const PinCheckSuccess();
}

/// PIN check gagal (salah)
class PinCheckFailure extends PinState {
  const PinCheckFailure();
}

/// PIN berhasil disimpan
class PinSetSuccess extends PinState {
  const PinSetSuccess();
}

/// PIN berhasil dihapus
class PinRemoveSuccess extends PinState {
  const PinRemoveSuccess();
}

/// Toggle enabled berhasil
class PinToggleSuccess extends PinState {
  final bool enabled;
  const PinToggleSuccess(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class PinError extends PinState {
  final String message;
  const PinError(this.message);
  @override
  List<Object?> get props => [message];
}
