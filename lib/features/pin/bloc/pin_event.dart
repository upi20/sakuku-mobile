import 'package:equatable/equatable.dart';

abstract class PinEvent extends Equatable {
  const PinEvent();
  @override
  List<Object?> get props => [];
}

/// Check apakah [pin] cocok dengan yang tersimpan
class PinCheck extends PinEvent {
  final String pin;
  const PinCheck(this.pin);
  @override
  List<Object?> get props => [pin];
}

/// Simpan PIN baru (sekaligus aktifkan)
class PinSet extends PinEvent {
  final String pin;
  const PinSet(this.pin);
  @override
  List<Object?> get props => [pin];
}

/// Hapus PIN dan nonaktifkan
class PinRemove extends PinEvent {
  const PinRemove();
}

/// Toggle aktif/nonaktif PIN.
/// Jika [enabled]=true tapi PIN belum ada, UI harus arahkan ke SetPinPage.
class PinToggleEnabled extends PinEvent {
  final bool enabled;
  const PinToggleEnabled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

/// Load status PIN (enabled, ada PIN tersimpan atau tidak)
class PinLoad extends PinEvent {
  const PinLoad();
}
