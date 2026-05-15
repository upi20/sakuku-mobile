import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../bloc/balancing_bloc.dart';
import '../model/balancing_item.dart';
import 'balancing_bulk_page.dart';
import 'balancing_denomination_sheet.dart';

class BalancingCheckPage extends StatefulWidget {
  const BalancingCheckPage({super.key});

  @override
  State<BalancingCheckPage> createState() => _BalancingCheckPageState();
}

class _BalancingCheckPageState extends State<BalancingCheckPage> {
  // Satu controller per rekening; key = account.id
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int accountId, double initialValue) {
    return _controllers.putIfAbsent(
      accountId,
      () => TextEditingController(
        text: ThousandsInputFormatter.formatForDisplay(initialValue.toInt()),
      ),
    );
  }

  void _resetController(
      BuildContext context, int accountId, double appBalance) {
    final ctrl = _controllers[accountId];
    if (ctrl == null) return;
    final formatted =
        ThousandsInputFormatter.formatForDisplay(appBalance.toInt());
    ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    context
        .read<BalancingBloc>()
        .add(BalancingRealBalanceChanged(accountId, appBalance));
  }

  void _onInputChanged(BuildContext context, int accountId, String value) {
    final raw = ThousandsInputFormatter.toRaw(value);
    final amount = double.tryParse(raw) ?? 0;
    context
        .read<BalancingBloc>()
        .add(BalancingRealBalanceChanged(accountId, amount));
  }

  void _openDenomination(BuildContext context, int accountId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BalancingDenominationSheet(
        onUse: (total) {
          final ctrl = _controllerFor(accountId, total);
          final formatted = ThousandsInputFormatter.formatForDisplay(total.toInt());
          ctrl.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
          context
              .read<BalancingBloc>()
              .add(BalancingDenominationUsed(accountId, total));
        },
      ),
    );
  }

  void _goNext(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BalancingBloc>(),
          child: const BalancingBulkPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Saldo  (Langkah 1 dari 3)'),
        elevation: 0,
      ),
      body: BlocBuilder<BalancingBloc, BalancingState>(
        builder: (context, state) {
          if (state is BalancingInitial || state is BalancingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BalancingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<BalancingBloc>()
                        .add(const BalancingLoad()),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is! BalancingLoaded) return const SizedBox.shrink();
          final items = state.items;

          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: 'Tidak ada rekening aktif',
            );
          }

          return Column(
            children: [
              // ── Header tabel ─────────────────────────────────
              Container(
                color: context.cs.primaryContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Rekening',
                            style: TextStyle(
                                color: context.cs.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        flex: 3,
                        child: Text('Sekarang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: context.cs.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        flex: 3,
                        child: Text('Aplikasi',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: context.cs.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        flex: 3,
                        child: Text('Selisih',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: context.cs.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),

              // ── List rekening ─────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final accId = item.account.id!;
                    final ctrl = _controllerFor(accId, item.appBalance);
                    return _AccountRow(
                      item: item,
                      controller: ctrl,
                      onChanged: (val) =>
                          _onInputChanged(context, accId, val),
                      onReset: () => _resetController(
                          context, accId, item.appBalance),
                      onDenomination: item.isDenominationEligible
                          ? () => _openDenomination(context, accId)
                          : null,
                    );
                  },
                ),
              ),

              // ── Total ─────────────────────────────────────────
              _TotalRow(
                totalReal: state.totalRealBalance,
                totalApp: state.totalAppBalance,
                totalSelisih: state.totalSelisih,
              ),

              // ── Tombol Lanjut ─────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _goNext(context),
                      child: const Text('Lanjut  →'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AccountRow extends StatelessWidget {
  final BalancingItem item;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onReset;
  final VoidCallback? onDenomination;

  const _AccountRow({
    required this.item,
    required this.controller,
    required this.onChanged,
    required this.onReset,
    this.onDenomination,
  });

  @override
  Widget build(BuildContext context) {
    final selisih = item.selisih;
    final selisihColor = selisih < 0
        ? context.cs.error
        : selisih > 0
            ? AppTheme.income
            : context.cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nama rekening
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ColoredIcon(
                  iconName: item.account.icon,
                  backgroundColor:
                      ColoredIcon.parseColor(item.account.color),
                  size: 28,
                  iconSize: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.account.name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Input Sekarang
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsInputFormatter()],
                      onChanged: onChanged,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4)),
                        // Tombol reset: tampil hanya jika nilai berbeda dari app
                        suffixIcon: selisih != 0
                            ? GestureDetector(
                                onTap: onReset,
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                ),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                      ),
                    ),
                  ),
                  if (onDenomination != null)
                    GestureDetector(
                      onTap: onDenomination,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(Icons.calculate_outlined,
                            size: 18, color: context.cs.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Saldo Aplikasi
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.format(item.appBalance),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Selisih
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.format(selisih),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selisihColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final double totalReal;
  final double totalApp;
  final double totalSelisih;

  const _TotalRow({
    required this.totalReal,
    required this.totalApp,
    required this.totalSelisih,
  });

  @override
  Widget build(BuildContext context) {
    final selisihColor = totalSelisih < 0
        ? context.cs.error
        : totalSelisih > 0
            ? AppTheme.income
            : context.cs.onSurfaceVariant;

    return Container(
      color: context.cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'TOTAL',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.cs.onSurface),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.format(totalReal),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.cs.onSurface),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.format(totalApp),
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.cs.onSurface),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.format(totalSelisih),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selisihColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
