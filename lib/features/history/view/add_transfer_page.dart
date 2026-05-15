import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/account_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../bloc/history_bloc.dart';
import '../bloc/transfer_bloc.dart';

class AddTransferPage extends StatefulWidget {
  const AddTransferPage({super.key});

  @override
  State<AddTransferPage> createState() => _AddTransferPageState();
}

class _AddTransferPageState extends State<AddTransferPage> {
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransferBloc>().add(TransferInit());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state is TransferSuccess) {
          context.read<HistoryBloc>().add(HistoryRefresh());
          context.pop();
        } else if (state is TransferError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transfer Saldo'),
          ),
          body: state is TransferReady
              ? _buildForm(context, state)
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, TransferReady state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Source account
                _AccountPickerCard(
                  label: 'DARI REKENING',
                  hint: 'Pilih Rekening Asal',
                  account: state.srcAccount,
                  balance: state.srcAccount != null
                      ? (state.balances[state.srcAccount!.id] ?? 0)
                      : null,
                  onTap: () => _pickSrc(context, state),
                ),
                // Dest account
                _AccountPickerCard(
                  label: 'KE REKENING',
                  hint: 'Pilih Rekening Tujuan',
                  account: state.destAccount,
                  balance: state.destAccount != null
                      ? (state.balances[state.destAccount!.id] ?? 0)
                      : null,
                  onTap: () => _pickDest(context, state),
                ),
                // Amount
                _InputCard(
                  label: 'JUMLAH',
                  hint: '0',
                  controller: _amountController,
                  isNumeric: true,
                ),
                // Fee
                _InputCard(
                  label: 'BIAYA TRANSFER (opsional)',
                  hint: '0',
                  controller: _feeController,
                  isNumeric: true,
                ),
                const SizedBox(height: 8),
                // Date + Time
                _DateTimeSection(date: state.date, time: state.time),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // Save button
        Container(
          color: context.cs.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<TransferBloc>()
                  ..add(TransferAmountChanged(
                      ThousandsInputFormatter.toRaw(_amountController.text)))
                  ..add(TransferFeeChanged(
                      ThousandsInputFormatter.toRaw(_feeController.text)))
                  ..add(TransferSubmit());
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simpan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  void _pickSrc(BuildContext context, TransferReady state) async {
    final bloc = context.read<TransferBloc>();
    final picked = await showModalBottomSheet<AccountModel>(
      context: context,
      builder: (_) => _AccountListSheet(
          accounts: state.accounts,
          balances: state.balances,
          title: 'Rekening Asal'),
    );
    if (picked != null && mounted) {
      bloc.add(TransferSrcAccountSelected(picked));
    }
  }

  void _pickDest(BuildContext context, TransferReady state) async {
    final bloc = context.read<TransferBloc>();
    final picked = await showModalBottomSheet<AccountModel>(
      context: context,
      builder: (_) => _AccountListSheet(
          accounts: state.accounts,
          balances: state.balances,
          title: 'Rekening Tujuan'),
    );
    if (picked != null && mounted) {
      bloc.add(TransferDestAccountSelected(picked));
    }
  }
}

class _AccountPickerCard extends StatelessWidget {
  final String label;
  final String hint;
  final AccountModel? account;
  final double? balance;
  final VoidCallback onTap;

  const _AccountPickerCard({
    required this.label,
    required this.hint,
    required this.account,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (balance != null) ...[const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(balance!),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: context.cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      account?.name ?? hint,
                      style: TextStyle(
                        color: account != null
                            ? null
                            : context.cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (account != null)
                    ColoredIcon(
                      iconName: account!.icon,
                      backgroundColor:
                          ColoredIcon.parseColor(account!.color),
                      size: 36,
                      iconSize: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isNumeric;

  const _InputCard({
    required this.label,
    required this.hint,
    required this.controller,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isNumeric) ...([
                const Text(
                  'Rp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ]),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      isNumeric ? TextInputType.number : TextInputType.text,
                  inputFormatters:
                      isNumeric ? [ThousandsInputFormatter()] : [],
                  maxLength: 19,
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTimeSection extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  const _DateTimeSection({required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.formatDate(
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null && context.mounted) {
                  context.read<TransferBloc>().add(TransferDateChanged(picked));
                }
              },
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(dateStr, style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null && context.mounted) {
                context.read<TransferBloc>().add(TransferTimeChanged(picked));
              }
            },
            icon: const Icon(Icons.access_time, size: 18),
            label: Text(timeStr, style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountListSheet extends StatelessWidget {
  final List<AccountModel> accounts;
  final Map<int, double> balances;
  final String title;

  const _AccountListSheet({
    required this.accounts,
    required this.balances,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: accounts.length,
            itemBuilder: (_, i) {
              final acc = accounts[i];
              final bg = ColoredIcon.parseColor(acc.color);
              final bal = balances[acc.id] ?? 0;
              return ListTile(
                leading:
                    ColoredIcon(iconName: acc.icon, backgroundColor: bg),
                title: Text(acc.name),
                subtitle: Text(
                  CurrencyFormatter.format(bal),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.of(context).pop(acc),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

