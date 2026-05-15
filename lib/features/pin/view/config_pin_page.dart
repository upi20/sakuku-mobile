import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../bloc/pin_bloc.dart';
import '../bloc/pin_event.dart';
import '../bloc/pin_state.dart';

class ConfigPinPage extends StatelessWidget {
  const ConfigPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PinBloc()..add(const PinLoad()),
      child: const _ConfigPinBody(),
    );
  }
}

class _ConfigPinBody extends StatelessWidget {
  const _ConfigPinBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinBloc, PinState>(
      listener: (context, state) {
        if (state is PinRemoveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN berhasil dihapus')),
          );
          // Reload
          context.read<PinBloc>().add(const PinLoad());
        } else if (state is PinToggleSuccess) {
          if (state.enabled) {
            // Aktifkan PIN: perlu buat PIN baru
            context.push('/pin/set').then((_) {
              if (context.mounted) {
                context.read<PinBloc>().add(const PinLoad());
              }
            });
          } else {
            context.read<PinBloc>().add(const PinLoad());
          }
        } else if (state is PinError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        bool isEnabled = false;
        bool hasPin = false;
        if (state is PinLoaded) {
          isEnabled = state.isEnabled;
          hasPin = state.hasPin;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Keamanan PIN'),
            elevation: 0,
          ),
          body: state is PinLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    // Toggle aktif/nonaktif
                    Card(
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: SwitchListTile(
                        value: isEnabled,
                        onChanged: (val) {
                          if (!val) {
                            // Nonaktifkan: konfirmasi dulu
                            ConfirmDialog.show(
                              context,
                              title: 'Nonaktifkan PIN',
                              message:
                                  'Apakah Anda yakin ingin menonaktifkan PIN keamanan?',
                              confirmLabel: 'Nonaktifkan',
                              onConfirm: () => context
                                  .read<PinBloc>()
                                  .add(const PinToggleEnabled(false)),
                            );
                          } else {
                            context
                                .read<PinBloc>()
                                .add(const PinToggleEnabled(true));
                          }
                        },
                        title: const Text(
                          'Aktifkan PIN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isEnabled
                              ? 'PIN aktif — app terkunci saat dibuka'
                              : 'PIN tidak aktif',
                        ),
                      ),
                    ),

                    // Ganti PIN (hanya tampil jika PIN aktif & sudah ada)
                    if (isEnabled && hasPin) ...[
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text(
                            'Ganti PIN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/pin/set?change=1').then((_) {
                              if (context.mounted) {
                                context
                                    .read<PinBloc>()
                                    .add(const PinLoad());
                              }
                            });
                          },
                        ),
                      ),

                      // Hapus PIN
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: context.cs.error),
                          title: Text(
                            'Hapus PIN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.cs.error),
                          ),
                          onTap: () {
                            ConfirmDialog.show(
                              context,
                              title: 'Hapus PIN',
                              message:
                                  'PIN akan dihapus dan keamanan aplikasi dinonaktifkan.',
                              confirmLabel: 'Hapus',
                              onConfirm: () => context
                                  .read<PinBloc>()
                                  .add(const PinRemove()),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
