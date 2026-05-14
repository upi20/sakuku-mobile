import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../bloc/pin_bloc.dart';
import '../bloc/pin_event.dart';
import '../bloc/pin_state.dart';
import 'pin_numpad.dart';

/// [isChange] true → judul "Ganti PIN", false → "Buat PIN"
class SetPinPage extends StatelessWidget {
  final bool isChange;
  const SetPinPage({super.key, this.isChange = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PinBloc(),
      child: _SetPinBody(isChange: isChange),
    );
  }
}

class _SetPinBody extends StatefulWidget {
  final bool isChange;
  const _SetPinBody({required this.isChange});

  @override
  State<_SetPinBody> createState() => _SetPinBodyState();
}

class _SetPinBodyState extends State<_SetPinBody> {
  // Step 1: input PIN baru, Step 2: konfirmasi
  bool _confirming = false;
  String _firstPin = '';
  String _input = '';
  bool _shaking = false;

  String get _title =>
      _confirming ? 'Konfirmasi PIN' : (widget.isChange ? 'PIN Baru' : 'Buat PIN');

  String get _subtitle =>
      _confirming ? 'Masukkan ulang PIN baru Anda' : 'Masukkan 4 digit PIN';

  void _onKey(String key) {
    if (_input.length >= 4) return;
    setState(() => _input += key);
    if (_input.length == 4) {
      if (!_confirming) {
        // Simpan PIN pertama, masuk step konfirmasi
        setState(() {
          _firstPin = _input;
          _input = '';
          _confirming = true;
        });
      } else {
        // Konfirmasi: cocok → simpan; tidak cocok → ulangi dari awal
        if (_input == _firstPin) {
          context.read<PinBloc>().add(PinSet(_input));
        } else {
          _shake();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN tidak cocok, mulai dari awal'),
              backgroundColor: AppColors.expense,
              duration: Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                _firstPin = '';
                _input = '';
                _confirming = false;
              });
            }
          });
        }
      }
    }
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _shake() {
    setState(() => _shaking = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _shaking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PinBloc, PinState>(
      listener: (context, state) {
        if (state is PinSetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN berhasil disimpan'),
              backgroundColor: AppColors.income,
            ),
          );
          context.pop();
        } else if (state is PinError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.isChange ? 'Ganti PIN' : 'Buat PIN'),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // PIN dots
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                transform: _shaking
                    ? Matrix4.translationValues(8.0, 0.0, 0.0)
                    : Matrix4.identity(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _input.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 48),
              PinNumpad(onKey: _onKey, onDelete: _onDelete),
            ],
          ),
        ),
      ),
    );
  }
}
