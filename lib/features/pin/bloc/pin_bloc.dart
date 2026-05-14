import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/pin_service.dart';
import 'pin_event.dart';
import 'pin_state.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  final PinService _service;

  PinBloc({PinService? service})
      : _service = service ?? PinService.instance,
        super(const PinInitial()) {
    on<PinLoad>(_onLoad);
    on<PinCheck>(_onCheck);
    on<PinSet>(_onSet);
    on<PinRemove>(_onRemove);
    on<PinToggleEnabled>(_onToggle);
  }

  Future<void> _onLoad(PinLoad event, Emitter<PinState> emit) async {
    emit(const PinLoading());
    try {
      final isEnabled = await _service.isPinEnabled();
      final storedPin = await _service.getPin();
      emit(PinLoaded(isEnabled: isEnabled, hasPin: storedPin != null));
    } catch (e) {
      emit(PinError(e.toString()));
    }
  }

  Future<void> _onCheck(PinCheck event, Emitter<PinState> emit) async {
    try {
      final ok = await _service.checkPin(event.pin);
      if (ok) {
        _service.unlockSession();
        emit(const PinCheckSuccess());
      } else {
        emit(const PinCheckFailure());
      }
    } catch (e) {
      emit(PinError(e.toString()));
    }
  }

  Future<void> _onSet(PinSet event, Emitter<PinState> emit) async {
    try {
      await _service.setPin(event.pin);
      emit(const PinSetSuccess());
    } catch (e) {
      emit(PinError(e.toString()));
    }
  }

  Future<void> _onRemove(PinRemove event, Emitter<PinState> emit) async {
    try {
      await _service.removePin();
      emit(const PinRemoveSuccess());
    } catch (e) {
      emit(PinError(e.toString()));
    }
  }

  Future<void> _onToggle(PinToggleEnabled event, Emitter<PinState> emit) async {
    try {
      await _service.setPinEnabled(event.enabled);
      emit(PinToggleSuccess(event.enabled));
    } catch (e) {
      emit(PinError(e.toString()));
    }
  }
}
