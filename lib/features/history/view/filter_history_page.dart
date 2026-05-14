import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/interfaces/i_category_repository.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../bloc/history_bloc.dart';

enum _DateRangeOption { all, today, thisMonth, thisYear, custom }

class FilterHistoryPage extends StatefulWidget {
  const FilterHistoryPage({super.key});

  @override
  State<FilterHistoryPage> createState() => _FilterHistoryPageState();
}

class _FilterHistoryPageState extends State<FilterHistoryPage> {
  _DateRangeOption _rangeOption = _DateRangeOption.all;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedAccountId;
  int? _selectedCategoryId;

  List<AccountModel> _accounts = [];
  List<CategoryModel> _incomeCategories = [];
  List<CategoryModel> _expenseCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accountRepo = context.read<IAccountRepository>();
    final categoryRepo = context.read<ICategoryRepository>();

    final accounts = await accountRepo.getAll();
    final incomeCategories = await categoryRepo.getBySign('+');
    final expenseCategories = await categoryRepo.getBySign('-');

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _incomeCategories = incomeCategories;
        _expenseCategories = expenseCategories;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title:
            const Text('Filter', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateRangeSection(),
                        if (_rangeOption == _DateRangeOption.custom)
                          _buildCustomDateSection(),
                        _buildAccountSection(),
                        _buildCategorySection(
                            'PEMASUKAN', _incomeCategories, true),
                        _buildCategorySection(
                            'PENGELUARAN', _expenseCategories, false),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                _buildFilterButton(),
              ],
            ),
    );
  }

  Widget _buildDateRangeSection() {
    final options = {
      _DateRangeOption.all: 'Semua',
      _DateRangeOption.today: 'Hari Ini',
      _DateRangeOption.thisMonth: 'Bulan Ini',
      _DateRangeOption.thisYear: 'Tahun Ini',
      _DateRangeOption.custom: 'Kustom',
    };
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RENTANG TANGGAL',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.entries.map((e) {
                final selected = _rangeOption == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _rangeOption = e.key;
                    }),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.darkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TANGGAL MULAI',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_startDate != null
                ? DateFormatter.formatDate(
                    '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}')
                : 'Pilih tanggal'),
          ),
          const SizedBox(height: 12),
          const Text('TANGGAL AKHIR',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_endDate != null
                ? DateFormatter.formatDate(
                    '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}')
                : 'Pilih tanggal'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8, bottom: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REKENING',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          if (_accounts.isEmpty)
            const Text('Belum ada rekening',
                style: TextStyle(color: AppColors.darkGray))
          else
            Wrap(
              spacing: 8,
              children: _accounts.map((acc) {
                final selected = _selectedAccountId == acc.id;
                return ChoiceChip(
                  avatar: Icon(
                    ColoredIcon(
                            iconName: acc.icon,
                            backgroundColor: ColoredIcon.parseColor(acc.color))
                        .iconName
                        .isNotEmpty
                        ? Icons.account_balance_wallet
                        : Icons.account_balance_wallet,
                    size: 16,
                    color: selected ? Colors.white : AppColors.darkGray,
                  ),
                  label: Text(acc.name),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedAccountId = selected ? null : acc.id;
                  }),
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.darkBlue,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      String title, List<CategoryModel> categories, bool isIncome) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          if (categories.isEmpty)
            const Text('Belum ada kategori',
                style: TextStyle(color: AppColors.darkGray))
          else
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final selected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedCategoryId = selected ? null : cat.id;
                  }),
                  selectedColor: isIncome ? AppColors.income : AppColors.expense,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.darkBlue,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _applyFilter,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Filter',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  void _applyFilter() async {
    final historyRepo = context.read<IHistoryRepository>();
    final now = DateTime.now();
    String? startDateStr;
    String? endDateStr;
    String? sign;

    switch (_rangeOption) {
      case _DateRangeOption.all:
        break;
      case _DateRangeOption.today:
        startDateStr = DateFormatter.todayString();
        endDateStr = startDateStr;
        break;
      case _DateRangeOption.thisMonth:
        startDateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        endDateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
        break;
      case _DateRangeOption.thisYear:
        startDateStr = '${now.year}-01-01';
        endDateStr = '${now.year}-12-31';
        break;
      case _DateRangeOption.custom:
        if (_startDate != null) {
          startDateStr =
              '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
        }
        if (_endDate != null) {
          endDateStr =
              '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
        }
        break;
    }

    // Determine sign from selected category
    if (_selectedCategoryId != null) {
      final allCategories = [..._incomeCategories, ..._expenseCategories];
      final cat = allCategories
          .where((c) => c.id == _selectedCategoryId)
          .firstOrNull;
      sign = cat?.sign;
    }

    await historyRepo.filter(
      startDate: startDateStr,
      endDate: endDateStr,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      sign: sign,
    );

    if (!mounted) return;

    // Reload current month after filter and go back
    context.read<HistoryBloc>().add(HistoryRefresh());
    context.pop();
  }
}
