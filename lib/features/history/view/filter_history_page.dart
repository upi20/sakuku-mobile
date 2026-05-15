import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/interfaces/i_category_repository.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../bloc/history_bloc.dart';

class FilterHistoryPage extends StatefulWidget {
  const FilterHistoryPage({super.key});

  @override
  State<FilterHistoryPage> createState() => _FilterHistoryPageState();
}

class _FilterHistoryPageState extends State<FilterHistoryPage> {
  HistoryViewMode _viewMode = HistoryViewMode.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<AccountModel> _accounts = [];
  List<CategoryModel> _incomeCategories = [];
  List<CategoryModel> _expenseCategories = [];

  // IDs of accounts/categories the user has CHECKED (included)
  Set<int> _checkedAccountIds = {};
  Set<int> _checkedCategoryIds = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate view mode and selections from current bloc state
    final state = context.read<HistoryBloc>().state;
    if (state is HistoryLoaded) {
      _viewMode = state.viewMode;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final accountRepo = context.read<IAccountRepository>();
    final categoryRepo = context.read<ICategoryRepository>();

    final accounts = await accountRepo.getAll();
    final incomeCategories = await categoryRepo.getBySign('+');
    final expenseCategories = await categoryRepo.getBySign('-');

    if (!mounted) return;

    // Read current filter from bloc AFTER data is loaded
    final state = context.read<HistoryBloc>().state;
    Set<int> currentAccountIds = {};
    Set<int> currentCategoryIds = {};
    if (state is HistoryLoaded) {
      currentAccountIds = state.selectedAccountIds;
      currentCategoryIds = state.selectedCategoryIds;
    }

    setState(() {
      _accounts = accounts;
      _incomeCategories = incomeCategories;
      _expenseCategories = expenseCategories;

      // Empty set in bloc = all selected; non-empty = only those IDs
      if (currentAccountIds.isEmpty) {
        _checkedAccountIds = {
          for (final a in accounts) if (a.id != null) a.id!
        };
      } else {
        _checkedAccountIds = Set.from(currentAccountIds);
      }

      if (currentCategoryIds.isEmpty) {
        _checkedCategoryIds = {
          for (final c in [...incomeCategories, ...expenseCategories])
            if (c.id != null) c.id!
        };
      } else {
        _checkedCategoryIds = Set.from(currentCategoryIds);
      }

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Filter'),
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
                        _buildViewModeSection(),
                        if (_viewMode == HistoryViewMode.custom)
                          _buildCustomDateSection(),
                        _buildAccountSection(),
                        _buildCategorySection(
                            'PENDAPATAN', _incomeCategories),
                        _buildCategorySection(
                            'PENGELUARAN', _expenseCategories),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildFilterButton(),
              ],
            ),
    );
  }

  Widget _buildViewModeSection() {
    const options = [
      (HistoryViewMode.all, 'Semua'),
      (HistoryViewMode.daily, 'Harian'),
      (HistoryViewMode.monthly, 'Bulanan'),
      (HistoryViewMode.yearly, 'Tahunan'),
      (HistoryViewMode.custom, 'Sesuaikan'),
    ];
    return Container(
      color: context.cs.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RENTANG WAKTU',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final selected = _viewMode == opt.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(opt.$2),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _viewMode = opt.$1),
                    showCheckmark: false,
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
      color: context.cs.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TANGGAL MULAI',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _customStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null && mounted) {
                setState(() => _customStartDate = picked);
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_customStartDate != null
                ? DateFormatter.formatDate(_dateStr(_customStartDate!))
                : 'Pilih tanggal'),
          ),
          const SizedBox(height: 12),
          const Text(
            'TANGGAL AKHIR',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _customEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null && mounted) {
                setState(() => _customEndDate = picked);
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_customEndDate != null
                ? DateFormatter.formatDate(_dateStr(_customEndDate!))
                : 'Pilih tanggal'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    if (_accounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('REKENING'),
        ..._accounts.map((acc) => _buildCheckItem(
              icon: acc.icon,
              color: acc.color,
              name: acc.name,
              checked: _checkedAccountIds.contains(acc.id),
              onTap: () => setState(() {
                if (acc.id == null) return;
                if (_checkedAccountIds.contains(acc.id)) {
                  _checkedAccountIds.remove(acc.id);
                } else {
                  _checkedAccountIds.add(acc.id!);
                }
              }),
            )),
      ],
    );
  }

  Widget _buildCategorySection(
      String title, List<CategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title),
        ...categories.map((cat) => _buildCheckItem(
              icon: cat.icon,
              color: cat.color,
              name: cat.name,
              checked: _checkedCategoryIds.contains(cat.id),
              onTap: () => setState(() {
                if (cat.id == null) return;
                if (_checkedCategoryIds.contains(cat.id)) {
                  _checkedCategoryIds.remove(cat.id);
                } else {
                  _checkedCategoryIds.add(cat.id!);
                }
              }),
            )),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: context.cs.surfaceContainerLowest,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCheckItem({
    required String icon,
    required String? color,
    required String name,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: context.cs.surfaceContainerLowest,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ColoredIcon(
              iconName: icon,
              backgroundColor: ColoredIcon.parseColor(color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Icon(
              Icons.check,
              size: 20,
              color: checked ? context.cs.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _applyFilter,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'FILTER',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _applyFilter() {
    final totalCategories =
        _incomeCategories.length + _expenseCategories.length;

    // If all items are checked → send empty set (= no filter)
    final accountFilter =
        _checkedAccountIds.length == _accounts.length
            ? <int>{}
            : Set<int>.from(_checkedAccountIds);

    final categoryFilter =
        _checkedCategoryIds.length == totalCategories
            ? <int>{}
            : Set<int>.from(_checkedCategoryIds);

    context.read<HistoryBloc>().add(HistorySetMode(
          viewMode: _viewMode,
          selectedAccountIds: accountFilter,
          selectedCategoryIds: categoryFilter,
          customStartDate:
              _viewMode == HistoryViewMode.custom && _customStartDate != null
                  ? _dateStr(_customStartDate!)
                  : null,
          customEndDate:
              _viewMode == HistoryViewMode.custom && _customEndDate != null
                  ? _dateStr(_customEndDate!)
                  : null,
        ));

    context.pop();
  }
}
