import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pin_service.dart';
import '../bloc/pin_bloc.dart';
import '../bloc/pin_event.dart';
import '../bloc/pin_state.dart';
import 'pin_numpad.dart';

class CheckPinPage extends StatelessWidget {
  const CheckPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PinBloc(),
      child: const _CheckPinBody(),
    );
  }
}

class _CheckPinBody extends StatefulWidget {
  const _CheckPinBody();

  @override
  State<_CheckPinBody> createState() => _CheckPinBodyState();
}

class _CheckPinBodyState extends State<_CheckPinBody> {
  String _input = '';
  bool _shaking = false;

  // Bypass: tap logo 10x dalam 3 detik
  int _tapCount = 0;
  DateTime? _firstTapTime;

  void _onLogoTap() {
    final now = DateTime.now();
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 3)) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    if (_tapCount >= 10) {
      _tapCount = 0;
      _firstTapTime = null;
      PinService.instance.unlockSession();
      context.go('/history');
    }
  }

  void _onKey(String key) {
    if (_input.length >= 4) return;
    setState(() => _input += key);
    if (_input.length == 4) {
      context.read<PinBloc>().add(PinCheck(_input));
    }
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _reset({bool shake = false}) {
    setState(() {
      _input = '';
      _shaking = shake;
    });
    if (shake) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shaking = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PinBloc, PinState>(
      listener: (context, state) {
        if (state is PinCheckSuccess) {
          context.go('/history');
        } else if (state is PinCheckFailure) {
          _reset(shake: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN salah, coba lagi'),
              backgroundColor: AppColors.expense,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _onLogoTap,
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Masukkan PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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

