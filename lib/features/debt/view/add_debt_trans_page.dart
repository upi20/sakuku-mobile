import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/debt_trans_model.dart';
import '../../../core/repositories/local/account_repository.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../bloc/debt_trans_bloc.dart';
import '../bloc/debt_trans_event.dart';
import '../bloc/debt_trans_state.dart';
import 'debt_form_widgets.dart';

class AddDebtTransPage extends StatelessWidget {
  final int debtId;
  const AddDebtTransPage({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtTransBloc(),
      child: _AddDebtTransBody(debtId: debtId),
    );
  }
}

class _AddDebtTransBody extends StatefulWidget {
  final int debtId;
  const _AddDebtTransBody({required this.debtId});

  @override
  State<_AddDebtTransBody> createState() => _AddDebtTransBodyState();
}

class _AddDebtTransBodyState extends State<_AddDebtTransBody> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _type = 1; // 1=payment
  AccountModel? _selectedAccount;
  List<AccountModel> _accounts = [];
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final repo = AccountRepository();
    final list = await repo.getAll(activeOnly: true);
    if (mounted) setState(() => _accounts = list);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDateDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _save() {
    final raw = ThousandsInputFormatter.toRaw(_amountCtrl.text);
    final amount = double.tryParse(raw) ?? 0;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih rekening terlebih dahulu')));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah harus lebih dari 0')));
      return;
    }
    final dt = '${_formatDate(_date)} ${_formatTime(_time)}';
    context.read<DebtTransBloc>().add(DebtTransCreate(DebtTransModel(
          debtId: widget.debtId,
          accountId: _selectedAccount!.id!,
          amount: amount,
          note: _noteCtrl.text.trim(),
          dateTime: dt,
          type: _type,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        elevation: 0,
      ),
      body: BlocListener<DebtTransBloc, DebtTransState>(
        listener: (context, state) {
          if (state is DebtTransSuccess) {
            context.pop();
          } else if (state is DebtTransError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // Type
              Container(
                color: context.cs.surfaceContainerLowest,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: DebtTypeButton(
                        label: 'Pembayaran',
                        selected: _type == 1,
                        color: AppTheme.income,
                        onTap: () => setState(() => _type = 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DebtTypeButton(
                        label: 'Penambahan',
                        selected: _type == 2,
                        color: AppTheme.expense,
                        onTap: () => setState(() => _type = 2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DebtAccountSection(
                accounts: _accounts,
                selected: _selectedAccount,
                onPick: (acc) => setState(() => _selectedAccount = acc),
              ),
              const SizedBox(height: 8),
              DebtFormCard(
                label: 'JUMLAH',
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DebtFormCard(
                label: 'CATATAN',
                child: TextField(
                  controller: _noteCtrl,
                  maxLength: 500,
                  maxLines: 3,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                color: context.cs.surfaceContainerLowest,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TANGGAL',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: DebtDateButton(
                            label: _formatDateDisplay(_date),
                            icon: Icons.calendar_today,
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100));
                              if (d != null) setState(() => _date = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DebtDateButton(
                          label: _formatTime(_time),
                          icon: Icons.access_time,
                          onTap: () async {
                            final t = await showTimePicker(
                                context: context, initialTime: _time);
                            if (t != null) setState(() => _time = t);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SIMPAN',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
