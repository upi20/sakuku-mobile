import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/debt_trans_model.dart';
import '../../../core/repositories/local/account_repository.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../bloc/debt_trans_bloc.dart';
import '../bloc/debt_trans_event.dart';
import '../bloc/debt_trans_state.dart';
import 'debt_form_widgets.dart';

class EditDebtTransPage extends StatelessWidget {
  final int debtId;
  final int transId;
  const EditDebtTransPage(
      {super.key, required this.debtId, required this.transId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtTransBloc()..add(DebtTransLoad(debtId)),
      child: _EditDebtTransBody(debtId: debtId, transId: transId),
    );
  }
}

class _EditDebtTransBody extends StatefulWidget {
  final int debtId;
  final int transId;
  const _EditDebtTransBody({required this.debtId, required this.transId});

  @override
  State<_EditDebtTransBody> createState() => _EditDebtTransBodyState();
}

class _EditDebtTransBodyState extends State<_EditDebtTransBody> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _type = 1;
  AccountModel? _selectedAccount;
  List<AccountModel> _accounts = [];
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  DebtTransModel? _original;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final repo = AccountRepository();
    final list = await repo.getAll(activeOnly: true);
    if (!mounted) return;
    setState(() {
      _accounts = list;
      // Jika trans sudah di-prefill tapi account belum ke-set (race condition), coba lagi
      if (_original != null && _selectedAccount == null) {
        try {
          _selectedAccount =
              list.firstWhere((a) => a.id == _original!.accountId);
        } catch (_) {}
      }
    });
  }

  void _prefill(DebtTransModel t) {
    if (_loaded) return;
    _loaded = true;
    _original = t;
    _amountCtrl.text = ThousandsInputFormatter.formatForDisplay(t.amount);
    _noteCtrl.text = t.note;
    _type = t.type;
    try {
      _date = DateTime.parse(t.dateTime.substring(0, 10));
      final parts = t.dateTime.split(' ');
      if (parts.length > 1) {
        final tp = parts[1].split(':');
        _time = TimeOfDay(
            hour: int.parse(tp[0]), minute: int.parse(tp[1]));
      }
    } catch (_) {}
    try {
      _selectedAccount =
          _accounts.firstWhere((a) => a.id == t.accountId);
    } catch (_) {}
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
    if (_original == null) return;
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
    context.read<DebtTransBloc>().add(DebtTransUpdate(_original!.copyWith(
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Transaksi'),
        elevation: 0,
      ),
      body: BlocListener<DebtTransBloc, DebtTransState>(
        listener: (context, state) {
          if (state is DebtTransLoaded && !_loaded) {
            try {
              final t = state.transactions
                  .firstWhere((x) => x.id == widget.transId);
              setState(() => _prefill(t));
            } catch (_) {}
          } else if (state is DebtTransSuccess) {
            context.pop();
          } else if (state is DebtTransError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.expense));
          }
        },
        child: BlocBuilder<DebtTransBloc, DebtTransState>(
          builder: (context, state) {
            if (!_loaded && (state is DebtTransLoading || state is DebtTransInitial)) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Type
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DebtTypeButton(
                            label: 'Pembayaran',
                            selected: _type == 1,
                            color: AppColors.income,
                            onTap: () => setState(() => _type = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DebtTypeButton(
                            label: 'Penambahan',
                            selected: _type == 2,
                            color: AppColors.expense,
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue),
                      decoration: const InputDecoration(
                        hintText: 'Catatan (opsional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TANGGAL',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray)),
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
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
