import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';

class BalancingDenominationSheet extends StatefulWidget {
  /// Dipanggil saat user menekan "Gunakan Nilai Ini".
  final void Function(double total) onUse;

  const BalancingDenominationSheet({
    required this.onUse,
    super.key,
  });

  @override
  State<BalancingDenominationSheet> createState() =>
      _BalancingDenominationSheetState();
}

class _BalancingDenominationSheetState
    extends State<BalancingDenominationSheet> {
  static const _denominations = [
    100000, 50000, 20000, 10000, 5000,
    2000, 1000, 500, 200, 100,
  ];

  final Map<int, int> _counts = {
    100000: 0, 50000: 0, 20000: 0, 10000: 0, 5000: 0,
    2000: 0, 1000: 0, 500: 0, 200: 0, 100: 0,
  };

  late final Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final d in _denominations) d: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total =>
      _counts.entries.fold(0.0, (sum, e) => sum + e.key * e.value);

  void _setCount(int denom, int value) {
    final clamped = value.clamp(0, 9999);
    setState(() {
      _counts[denom] = clamped;
      final ctrl = _controllers[denom]!;
      final text = '$clamped';
      ctrl.value = ctrl.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _increment(int denom) => _setCount(denom, _counts[denom]! + 1);
  void _decrement(int denom) => _setCount(denom, _counts[denom]! - 1);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hitung Pecahan Uang Tunai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.darkGray),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Daftar denominasi
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _denominations.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final denom = _denominations[index];
                final count = _counts[denom]!;
                final subTotal = denom * count;
                final ctrl = _controllers[denom]!;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      // Label denominasi
                      Expanded(
                        flex: 3,
                        child: Text(
                          CurrencyFormatter.format(denom.toDouble()),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),

                      // Stepper + input manual
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepButton(
                            icon: Icons.remove,
                            onTap: count > 0 ? () => _decrement(denom) : null,
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 52,
                            height: 34,
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (val) {
                                final parsed = int.tryParse(val) ?? 0;
                                setState(() => _counts[denom] = parsed.clamp(0, 9999));
                              },
                              onTap: () {
                                // Pilih semua teks saat di-tap agar mudah diganti
                                ctrl.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: ctrl.text.length,
                                );
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _StepButton(
                            icon: Icons.add,
                            onTap: count < 9999 ? () => _increment(denom) : null,
                          ),
                        ],
                      ),

                      // Sub-total
                      Expanded(
                        flex: 3,
                        child: Text(
                          CurrencyFormatter.format(subTotal.toDouble()),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            color: subTotal > 0
                                ? AppColors.income
                                : AppColors.darkGray,
                            fontWeight: subTotal > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Total + tombol
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onUse(_total);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Gunakan Nilai Ini',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.disabled,
        ),
      ),
    );
  }
}
