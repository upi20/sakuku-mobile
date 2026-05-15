import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/debt_model.dart';
import '../../../core/repositories/local/account_repository.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';
import 'debt_form_widgets.dart';

class EditDebtPage extends StatelessWidget {
  final int debtId;
  const EditDebtPage({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtBloc()..add(DebtLoadDetail(debtId)),
      child: _EditDebtBody(debtId: debtId),
    );
  }
}

class _EditDebtBody extends StatefulWidget {
  final int debtId;
  const _EditDebtBody({required this.debtId});

  @override
  State<_EditDebtBody> createState() => _EditDebtBodyState();
}

class _EditDebtBodyState extends State<_EditDebtBody> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int _type = 1;
  AccountModel? _selectedAccount;
  List<AccountModel> _accounts = [];
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DebtModel? _original;
  bool _loaded = false;

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

  void _prefill(DebtModel debt) {
    if (_loaded) return;
    _loaded = true;
    _original = debt;
    _nameCtrl.text = debt.name;
    _noteCtrl.text = debt.note;
    _amountCtrl.text = ThousandsInputFormatter.formatForDisplay(debt.amount);
    _type = debt.type;
    try {
      _startDate = DateTime.parse(debt.startDateTime.substring(0, 10));
      final parts = debt.startDateTime.split(' ');
      if (parts.length > 1) {
        final tp = parts[1].split(':');
        _startTime = TimeOfDay(
            hour: int.parse(tp[0]), minute: int.parse(tp[1]));
      }
    } catch (_) {}
    if (debt.endDateTime.isNotEmpty) {
      try {
        _endDate = DateTime.parse(debt.endDateTime.substring(0, 10));
        final parts = debt.endDateTime.split(' ');
        if (parts.length > 1) {
          final tp = parts[1].split(':');
          _endTime = TimeOfDay(
              hour: int.parse(tp[0]), minute: int.parse(tp[1]));
        }
      } catch (_) {}
    }
    // Find matching account
    try {
      _selectedAccount =
          _accounts.firstWhere((a) => a.id == debt.accountId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _amountCtrl.dispose();
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
    final name = _nameCtrl.text.trim();
    final raw = ThousandsInputFormatter.toRaw(_amountCtrl.text);
    final amount = double.tryParse(raw) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama harus diisi')));
      return;
    }
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
    final startDt = '${_formatDate(_startDate)} ${_formatTime(_startTime)}';
    final endDt = _endDate != null
        ? '${_formatDate(_endDate!)} ${_formatTime(_endTime ?? const TimeOfDay(hour: 23, minute: 59))}'
        : '';
    context.read<DebtBloc>().add(DebtUpdate(_original!.copyWith(
          accountId: _selectedAccount!.id!,
          name: name,
          amount: amount,
          note: _noteCtrl.text.trim(),
          startDateTime: startDt,
          endDateTime: endDt,
          type: _type,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hutang/Piutang'),
        elevation: 0,
      ),
      body: BlocListener<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state is DebtDetailLoaded && !_loaded) {
            setState(() => _prefill(state.debt));
          } else if (state is DebtSuccess) {
            context.pop();
          } else if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message)));
          }
        },
        child: BlocBuilder<DebtBloc, DebtState>(
          builder: (context, state) {
            if (!_loaded && (state is DebtLoading || state is DebtInitial)) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  Container(
                    color: context.cs.surfaceContainerLowest,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DebtTypeButton(
                            label: 'Hutang',
                            selected: _type == 1,
                            color: AppTheme.expense,
                            onTap: () => setState(() => _type = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DebtTypeButton(
                            label: 'Piutang',
                            selected: _type == 2,
                            color: AppTheme.income,
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
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DebtFormCard(
                    label: 'NAMA',
                    child: TextField(
                      controller: _nameCtrl,
                      maxLength: 500,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Nama hutang/piutang',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        counterText: '',
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
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DebtDateSection(
                    startDate: _startDate,
                    startTime: _startTime,
                    endDate: _endDate,
                    endTime: _endTime,
                    onPickStart: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100));
                      if (d != null) setState(() => _startDate = d);
                    },
                    onPickStartTime: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _startTime);
                      if (t != null) setState(() => _startTime = t);
                    },
                    onPickEnd: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100));
                      if (d != null) setState(() => _endDate = d);
                    },
                    onPickEndTime: () async {
                      final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime ??
                              const TimeOfDay(hour: 23, minute: 59));
                      if (t != null) setState(() => _endTime = t);
                    },
                    onClearEnd: () =>
                        setState(() { _endDate = null; _endTime = null; }),
                    formatDateDisplay: _formatDateDisplay,
                    formatTime: _formatTime,
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
