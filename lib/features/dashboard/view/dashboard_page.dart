import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../core/repositories/local/debt_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/history_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../../history/widgets/history_list_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  _DashboardFilter _selectedFilter = _DashboardFilter.today;
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _refresh() async {
    final next = _loadData();
    setState(() => _future = next);
    await next;
  }

  Future<_DashboardData> _loadData() async {
    final accountRepo = context.read<IAccountRepository>();
    final historyRepo = context.read<IHistoryRepository>();
    final debtRepo = DebtRepository();

    final now = DateTime.now();
    final summaryRange = _summaryRange(now, _selectedFilter);
    final chartRange = _chartRange(now, _selectedFilter);

    final results = await Future.wait<dynamic>([
      accountRepo.getAllBalances(),
      historyRepo.getByDateRange(summaryRange.$1, summaryRange.$2, excludeTransfer: true),
      historyRepo.getByDateRange(chartRange.$1, chartRange.$2, excludeTransfer: true),
      historyRepo.filter(excludeTransfer: true),
      historyRepo.getReportByCategory(
        startDate: summaryRange.$1,
        endDate: summaryRange.$2,
        sign: '-',
      ),
      debtRepo.getAll(type: 1, isRelief: false),
      debtRepo.getAll(type: 2, isRelief: false),
    ]);

    final balances = results[0] as Map<int, double>;
    final summaryItems = results[1] as List<HistoryModel>;
    final chartItems = results[2] as List<HistoryModel>;
    final allItems = results[3] as List<HistoryModel>;
    final topCategoryRows = results[4] as List<Map<String, dynamic>>;
    final unpaidDebts = results[5] as List;
    final unpaidLoans = results[6] as List;

    // Debug logs: periksa data yang diterima dari repository
    // debugPrint('Dashboard: summaryRange=$summaryRange, chartRange=$chartRange');
    // debugPrint('Dashboard: summaryItems=${summaryItems.length}, chartItems=${chartItems.length}, allItems=${allItems.length}');
    // debugPrint('Dashboard: topCategoryRows=${topCategoryRows.length}, unpaidDebts=${unpaidDebts.length}, unpaidLoans=${unpaidLoans.length}');

    final totalBalance = balances.values.fold<double>(0, (sum, v) => sum + v);

    double income = 0;
    double expense = 0;
    for (final item in summaryItems) {
      if (!_isCashflowItem(item)) continue;
      if (item.sign == '+') {
        income += item.amount;
      } else if (item.sign == '-') {
        expense += item.amount;
      }
    }

    final labels = <String>[];
    final expenseMap = <String, double>{};
    final chartStart = DateTime.parse(chartRange.$1);
    final chartEnd = DateTime.parse(chartRange.$2);
    for (
      var day = chartStart;
      !day.isAfter(chartEnd);
      day = day.add(const Duration(days: 1))
    ) {
      final key = _toDateString(day);
      labels.add(key);
      expenseMap[key] = 0;
    }

    // Pastikan defensif: keluarkan juga kategori transfer jika ada
    final filteredChartItems = chartItems
      .where((i) => i.categoryId != 1 && i.categoryId != 2)
      .toList();
    for (final item in filteredChartItems) {
      if (!_isCashflowItem(item) || item.sign != '-') continue;
      if (!expenseMap.containsKey(item.date)) continue;
      expenseMap[item.date] = (expenseMap[item.date] ?? 0) + item.amount;
    }

    final chartData = labels
        .map((d) => _DailyExpense(date: d, amount: expenseMap[d] ?? 0))
        .toList();

    // Recent transactions: collapse transfer pairs, keep latest few.
    final recent = <HistoryModel>[];
    final seenTransfers = <int>{};
    for (final item in allItems) {
      if (item.type == 2 && item.transferId > 0) {
        if (seenTransfers.contains(item.transferId)) continue;
        seenTransfers.add(item.transferId);
      }
      recent.add(item);
      if (recent.length >= 6) break;
    }

    final topCategories = topCategoryRows
        .map(
          (row) => _CategorySpend(
            name: (row['category_name'] as String?) ?? '-',
            icon: (row['category_icon'] as String?) ?? 'ic_other',
            color: (row['category_color'] as String?) ?? '#9E9E9E',
            amount: (row['total_amount'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((c) => c.amount > 0)
        .take(4)
        .toList();

    double debtRemaining = 0;
    for (final d in unpaidDebts) {
      debtRemaining += (d.remainingAmount as double);
    }
    double loanRemaining = 0;
    for (final l in unpaidLoans) {
      loanRemaining += (l.remainingAmount as double);
    }

    return _DashboardData(
      totalBalance: totalBalance,
      income: income,
      expense: expense,
      chartData: chartData,
      recent: recent,
      topCategories: topCategories,
      debtRemaining: debtRemaining,
      loanRemaining: loanRemaining,
      filterLabel: _selectedFilter.label,
      chartTitle: _selectedFilter.chartTitle,
    );
  }

  (String, String) _summaryRange(DateTime now, _DashboardFilter filter) {
    final today = _toDateString(now);
    switch (filter) {
      case _DashboardFilter.today:
        return (today, today);
      case _DashboardFilter.last7Days:
        final start = _toDateString(now.subtract(const Duration(days: 6)));
        return (start, today);
      case _DashboardFilter.monthToDate:
        final start = _toDateString(DateTime(now.year, now.month, 1));
        return (start, today);
    }
  }

  (String, String) _chartRange(DateTime now, _DashboardFilter filter) {
    final today = _toDateString(now);
    switch (filter) {
      case _DashboardFilter.today:
      case _DashboardFilter.last7Days:
        final start = _toDateString(now.subtract(const Duration(days: 6)));
        return (start, today);
      case _DashboardFilter.monthToDate:
        final start = _toDateString(DateTime(now.year, now.month, 1));
        return (start, today);
    }
  }

  String _toDateString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _onFilterSelected(_DashboardFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _future = _loadData();
    });
  }

  bool _isCashflowItem(HistoryModel item) {
    // Exclude transfer legs (both in/out), keep regular transactions and fees.
    return item.transferId == 0 || item.type == 4;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(onRetry: _refresh);
            }
            final data = snapshot.data!;
            final net = data.income - data.expense;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _HeaderRow(
                    selectedFilter: _selectedFilter,
                    onSelected: _onFilterSelected,
                  ),
                  const SizedBox(height: 16),
                  _BalanceCard(totalBalance: data.totalBalance),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricChip(
                          label: 'Masuk',
                          amount: data.income,
                          icon: Icons.trending_up,
                          color: AppTheme.income,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricChip(
                          label: 'Keluar',
                          amount: data.expense,
                          icon: Icons.trending_down,
                          color: AppTheme.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricChip(
                          label: 'Sisa',
                          amount: net,
                          icon: Icons.account_balance_wallet,
                          color: AppTheme.balanced,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Periode: ${data.filterLabel}',
                      style: context.tt.labelMedium?.copyWith(
                        color: context.cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExpenseChartCard(
                    title: data.chartTitle,
                    data: data.chartData,
                  ),
                  const SizedBox(height: 14),
                  // if (data.debtRemaining > 0 || data.loanRemaining > 0) ...[
                  //   _DebtSummaryCard(
                  //     debtRemaining: data.debtRemaining,
                  //     loanRemaining: data.loanRemaining,
                  //   ),
                  //   const SizedBox(height: 14),
                  // ],
                  // if (data.topCategories.isNotEmpty) ...[
                  //   _TopCategoriesCard(categories: data.topCategories),
                  //   const SizedBox(height: 14),
                  // ],

                  _MenuGrid(),
                  const SizedBox(height: 16),
                  _RecentTransactions(items: data.recent),
                  const SizedBox(height: 16),
                  // _MenuGrid(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final _DashboardFilter selectedFilter;
  final ValueChanged<_DashboardFilter> onSelected;

  const _HeaderRow({required this.selectedFilter, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Halo',
            style: context.tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<_DashboardFilter>(
          initialValue: selectedFilter,
          onSelected: onSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _DashboardFilter.today,
              child: Text('Hari ini'),
            ),
            PopupMenuItem(
              value: _DashboardFilter.last7Days,
              child: Text('7 hari terakhir'),
            ),
            PopupMenuItem(
              value: _DashboardFilter.monthToDate,
              child: Text('Bulan ini'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedFilter.label,
                  style: context.tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.tune, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double totalBalance;

  const _BalanceCard({required this.totalBalance});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SALDO',
            style: context.tt.labelLarge?.copyWith(
              letterSpacing: 1.1,
              color: cs.onPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(totalBalance),
            style: context.tt.headlineMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.tt.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseChartCard extends StatelessWidget {
  final String title;
  final List<_DailyExpense> data;

  const _ExpenseChartCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, e) => s + e.amount);
    final maxY = data.fold<double>(0, (m, e) => e.amount > m ? e.amount : m);
    final avg = data.isEmpty ? 0.0 : total / data.length;

    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              Text(
                'Total ${CurrencyFormatter.format(total)}',
                style: context.tt.bodySmall?.copyWith(
                  color: AppTheme.expense,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Rata-rata ${CurrencyFormatter.formatCompact(avg)}/hari',
                style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SimpleExpenseChart(data: data, maxValue: maxY),
        ],
      ),
    );
  }
}

class _SimpleExpenseChart extends StatelessWidget {
  final List<_DailyExpense> data;
  final double maxValue;

  const _SimpleExpenseChart({required this.data, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 168);
    }

    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final item in data)
            Expanded(
              child: _SimpleBar(
                amount: item.amount,
                maxValue: maxValue,
                isMax: item.amount > 0 && item.amount == maxValue,
                dayLabel: DateFormatter.dayName(
                  DateTime.parse(item.date).weekday,
                ).substring(0, 3),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleBar extends StatelessWidget {
  final double amount;
  final double maxValue;
  final bool isMax;
  final String dayLabel;

  const _SimpleBar({
    required this.amount,
    required this.maxValue,
    required this.isMax,
    required this.dayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final ratio = (amount / safeMax).clamp(0.0, 1.0);
    final barHeight = 110.0 * ratio;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amount > 0 ? CurrencyFormatter.formatCompact(amount) : '-',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: context.tt.labelSmall?.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: amount > 0
                ? AppTheme.expense
                : context.cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: barHeight < 4 ? 4 : barHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.expense.withValues(alpha: isMax ? 1 : 0.85),
                AppTheme.expense.withValues(alpha: isMax ? 0.7 : 0.4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: context.tt.labelSmall?.copyWith(
            color: context.cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Debt summary ─────────────────────────────────────────────────────────

class _DebtSummaryCard extends StatelessWidget {
  final double debtRemaining;
  final double loanRemaining;

  const _DebtSummaryCard({
    required this.debtRemaining,
    required this.loanRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.go('/debt'),
      child: Container(
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cs.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _DebtCell(
                label: 'Sisa Hutang',
                amount: debtRemaining,
                icon: Icons.south_west,
                color: AppTheme.expense,
              ),
            ),
            Container(
              width: 1,
              height: 38,
              color: context.cs.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: _DebtCell(
                label: 'Sisa Piutang',
                amount: loanRemaining,
                icon: Icons.north_east,
                color: AppTheme.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtCell extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _DebtCell({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.tt.labelSmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.formatCompact(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top categories ───────────────────────────────────────────────────────

class _TopCategoriesCard extends StatelessWidget {
  final List<_CategorySpend> categories;

  const _TopCategoriesCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    final maxAmount = categories.fold<double>(
      0,
      (m, c) => c.amount > m ? c.amount : m,
    );
    final safeMax = maxAmount <= 0 ? 1.0 : maxAmount;

    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Pengeluaran',
            style: context.tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _CategoryRow(
              category: categories[i],
              ratio: (categories[i].amount / safeMax).clamp(0.0, 1.0),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _CategorySpend category;
  final double ratio;

  const _CategoryRow({required this.category, required this.ratio});

  @override
  Widget build(BuildContext context) {
    final color = ColoredIcon.parseColor(category.color);
    return Row(
      children: [
        ColoredIcon(
          iconName: category.icon,
          backgroundColor: color,
          size: 34,
          iconSize: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCompact(category.amount),
                    style: context.tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: context.cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recent transactions ──────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final List<HistoryModel> items;

  const _RecentTransactions({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Transaksi Terakhir',
                  style: context.tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/history'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cs.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: context.cs.onSurfaceVariant,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada transaksi',
                  style: context.tt.bodyMedium?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in items)
            HistoryListItem(
              item: item,
              onTap: () {
                if (item.type == 2 || item.type == 4) {
                  context.push('/history/transfer/${item.transferId}');
                } else {
                  context.push('/history/${item.id}');
                }
              },
            ),
      ],
    );
  }
}

// ─── Menu grid ────────────────────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Menggunakan Row agar menjadi 1 baris
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Mengatur jarak antar icon
      children: const [
        _CircularMenuIcon(
          icon: Icons.receipt_long,
          route: '/history',
          color: Color(0xFF005EA8),
        ),
        _CircularMenuIcon(
          icon: Icons.assessment,
          route: '/report',
          color: Color(0xFF00695C),
        ),
        _CircularMenuIcon(
          icon: Icons.credit_score,
          route: '/debt',
          color: Color(0xFF8A4B00),
        ),
        _CircularMenuIcon(
          icon: Icons.tune,
          route: '/settings',
          color: Color(0xFF5C3B8A),
        ),
      ],
    );
  }
}

// Widget baru khusus untuk icon bulat tanpa text/card
class _CircularMenuIcon extends StatelessWidget {
  final IconData icon;
  final String route;
  final Color color;

  const _CircularMenuIcon({
    Key? key,
    required this.icon,
    required this.route,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.go(route);
      },
      borderRadius: BorderRadius.circular(50), // Efek ripple berbentuk bulat
      child: Container(
        padding: const EdgeInsets.all(16), // Menentukan besar lingkaran
        decoration: BoxDecoration(
          color: color, // Warna latar belakang bulat
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white, // Warna icon di dalam lingkaran
          size: 28,
        ),
      ),
    );
  }
}

// class _MenuGrid extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GridView.count(
//       crossAxisCount: 2,
//       crossAxisSpacing: 10,
//       mainAxisSpacing: 10,
//       childAspectRatio: 1.7,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       children: const [
//         _MenuTile(
//           icon: Icons.receipt_long,
//           label: 'Transaksi',
//           route: '/history',
//           color: Color(0xFF005EA8),
//         ),
//         _MenuTile(
//           icon: Icons.assessment,
//           label: 'Laporan',
//           route: '/report',
//           color: Color(0xFF00695C),
//         ),
//         _MenuTile(
//           icon: Icons.credit_score,
//           label: 'Hutang',
//           route: '/debt',
//           color: Color(0xFF8A4B00),
//         ),
//         _MenuTile(
//           icon: Icons.tune,
//           label: 'Pengaturan',
//           route: '/settings',
//           color: Color(0xFF5C3B8A),
//         ),
//       ],
//     );
//   }
// }

// class _MenuTile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String route;
//   final Color color;

//   const _MenuTile({
//     required this.icon,
//     required this.label,
//     required this.route,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(18),
//       onTap: () => context.go(route),
//       child: Ink(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           color: color.withValues(alpha: 0.08),
//           border: Border.all(color: color.withValues(alpha: 0.16)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: color.withValues(alpha: 0.15),
//               ),
//               child: Icon(icon, color: color, size: 22),
//             ),
//             const SizedBox(width: 10),
//             Text(
//               label,
//               style: context.tt.titleSmall?.copyWith(
//                 fontWeight: FontWeight.w700,
//                 color: context.cs.onSurface,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: context.cs.error, size: 30),
            const SizedBox(height: 10),
            Text(
              'Gagal memuat dashboard',
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  final double totalBalance;
  final double income;
  final double expense;
  final List<_DailyExpense> chartData;
  final List<HistoryModel> recent;
  final List<_CategorySpend> topCategories;
  final double debtRemaining;
  final double loanRemaining;
  final String filterLabel;
  final String chartTitle;

  const _DashboardData({
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.chartData,
    required this.recent,
    required this.topCategories,
    required this.debtRemaining,
    required this.loanRemaining,
    required this.filterLabel,
    required this.chartTitle,
  });
}

enum _DashboardFilter { today, last7Days, monthToDate }

extension _DashboardFilterX on _DashboardFilter {
  String get label {
    switch (this) {
      case _DashboardFilter.today:
        return 'Hari ini';
      case _DashboardFilter.last7Days:
        return '7 hari';
      case _DashboardFilter.monthToDate:
        return 'Bulan ini';
    }
  }

  String get chartTitle {
    switch (this) {
      case _DashboardFilter.today:
      case _DashboardFilter.last7Days:
        return 'Chart Pengeluaran 7 Hari Terakhir';
      case _DashboardFilter.monthToDate:
        return 'Chart Pengeluaran Bulan Ini';
    }
  }
}

class _DailyExpense {
  final String date;
  final double amount;

  const _DailyExpense({required this.date, required this.amount});
}

class _CategorySpend {
  final String name;
  final String icon;
  final String color;
  final double amount;

  const _CategorySpend({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });
}
