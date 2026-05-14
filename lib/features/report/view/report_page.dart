import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

enum _DateRangeMode { semua, harian, bulanan, tahunan, custom }

// Cache filter state agar tidak reset saat ganti tab
class _ReportFilterCache {
  static _DateRangeMode mode = _DateRangeMode.bulanan;
  static DateTime current = DateTime.now();
  static DateTime? customStart;
  static DateTime? customEnd;
}

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportBody();
  }
}

class _ReportBody extends StatefulWidget {
  const _ReportBody();

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  late _DateRangeMode _mode;
  late DateTime _current;
  DateTime? _customStart;
  DateTime? _customEnd;

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    // Restore dari cache
    _mode = _ReportFilterCache.mode;
    _current = _ReportFilterCache.current;
    _customStart = _ReportFilterCache.customStart;
    _customEnd = _ReportFilterCache.customEnd;
    // Hanya reload jika bloc belum punya data
    final bloc = context.read<ReportBloc>();
    if (bloc.state is ReportInitial) {
      bloc.add(ReportLoadSummary(startDate: _startDate, endDate: _endDate));
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _startDate {
    switch (_mode) {
      case _DateRangeMode.semua:
        return '2000-01-01';
      case _DateRangeMode.harian:
        return _fmt(_current);
      case _DateRangeMode.bulanan:
        return '${_current.year}-${_current.month.toString().padLeft(2, '0')}-01';
      case _DateRangeMode.tahunan:
        return '${_current.year}-01-01';
      case _DateRangeMode.custom:
        return _customStart != null ? _fmt(_customStart!) : _fmt(_current);
    }
  }

  String get _endDate {
    switch (_mode) {
      case _DateRangeMode.semua:
        return '2999-12-31';
      case _DateRangeMode.harian:
        return _fmt(_current);
      case _DateRangeMode.bulanan:
        return '${_current.year}-${_current.month.toString().padLeft(2, '0')}-31';
      case _DateRangeMode.tahunan:
        return '${_current.year}-12-31';
      case _DateRangeMode.custom:
        return _customEnd != null ? _fmt(_customEnd!) : _fmt(_current);
    }
  }

  String get _currentLabel {
    switch (_mode) {
      case _DateRangeMode.semua:
        return 'Semua';
      case _DateRangeMode.harian:
        return '${_current.day} ${_monthNames[_current.month - 1]} ${_current.year}';
      case _DateRangeMode.bulanan:
        return '${_monthNames[_current.month - 1]} ${_current.year}';
      case _DateRangeMode.tahunan:
        return '${_current.year}';
      case _DateRangeMode.custom:
        if (_customStart != null && _customEnd != null) {
          return '${_fmt(_customStart!)} — ${_fmt(_customEnd!)}';
        }
        return 'Sesuaikan';
    }
  }

  bool get _canNavigate =>
      _mode != _DateRangeMode.semua && _mode != _DateRangeMode.custom;

  void _prev() {
    setState(() {
      switch (_mode) {
        case _DateRangeMode.harian:
          _current = _current.subtract(const Duration(days: 1));
        case _DateRangeMode.bulanan:
          _current = DateTime(_current.year, _current.month - 1);
        case _DateRangeMode.tahunan:
          _current = DateTime(_current.year - 1);
        default:
          break;
      }
      _ReportFilterCache.current = _current;
    });
    _reload();
  }

  void _next() {
    setState(() {
      switch (_mode) {
        case _DateRangeMode.harian:
          _current = _current.add(const Duration(days: 1));
        case _DateRangeMode.bulanan:
          _current = DateTime(_current.year, _current.month + 1);
        case _DateRangeMode.tahunan:
          _current = DateTime(_current.year + 1);
        default:
          break;
      }
      _ReportFilterCache.current = _current;
    });
    _reload();
  }

  void _reload() {
    context.read<ReportBloc>().add(
        ReportLoadSummary(startDate: _startDate, endDate: _endDate));
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<_DateRangeMode>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _FilterSheet(currentMode: _mode),
    );
    if (result == null) return;
    if (!mounted) return;
    if (result == _DateRangeMode.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: _customStart != null && _customEnd != null
            ? DateTimeRange(start: _customStart!, end: _customEnd!)
            : null,
        locale: const Locale('id'),
      );
      if (range != null && mounted) {
        setState(() {
          _mode = _DateRangeMode.custom;
          _customStart = range.start;
          _customEnd = range.end;
          _ReportFilterCache.mode = _mode;
          _ReportFilterCache.customStart = _customStart;
          _ReportFilterCache.customEnd = _customEnd;
        });
        _reload();
      }
    } else {
      setState(() {
        _mode = result;
        _ReportFilterCache.mode = _mode;
        _ReportFilterCache.current = _current;
      });
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Laporan'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter rentang waktu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: Column(
          children: [
            // Header navigasi
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  if (_canNavigate)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.darkBlue),
                      onPressed: _prev,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      _currentLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue),
                    ),
                  ),
                  if (_canNavigate)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          color: AppColors.darkBlue),
                      onPressed: _next,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state is ReportLoading || state is ReportInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ReportSummaryLoaded) {
                    return _buildContent(context, state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportSummaryLoaded state) {
    final isEmpty = state.totalIncome == 0 && state.totalExpense == 0;
    return ListView(
      children: [
        // Info banner: transfer tidak dihitung
        Container(
          color: const Color(0xFFE3F2FD),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pengecualian data transfer antar rekening pada laporan',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        // Summary card
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 2),
          child: Column(
            children: [
              _SummaryRow(
                  label: 'Pendapatan',
                  amount: state.totalIncome,
                  color: AppColors.income),
              _SummaryRow(
                  label: 'Pengeluaran',
                  amount: state.totalExpense,
                  color: AppColors.expense),
              const Divider(height: 16),
              _SummaryRow(
                  label: 'Total',
                  amount: state.totalIncome - state.totalExpense,
                  color: AppColors.primarySoft),
            ],
          ),
        ),
        if (isEmpty)
          const SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined,
                      size: 64, color: AppColors.darkGray),
                  SizedBox(height: 8),
                  Text('Tidak ada laporan',
                      style: TextStyle(color: AppColors.darkGray)),
                ],
              ),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          _ChartSection(
            title: 'Pendapatan',
            startDate: _startDate,
            endDate: _endDate,
            sign: '+',
            items: state.incomeItems,
            chartColor: AppColors.income,
          ),
          const SizedBox(height: 8),
          _ChartSection(
            title: 'Pengeluaran',
            startDate: _startDate,
            endDate: _endDate,
            sign: '-',
            items: state.expenseItems,
            chartColor: AppColors.expense,
          ),
          const SizedBox(height: 8),
          // Tombol ke laporan list
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Laporan List',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue)),
                const Divider(height: 16),
                GestureDetector(
                  onTap: () {
                    final encodedStart = Uri.encodeQueryComponent(_startDate);
                    final encodedEnd = Uri.encodeQueryComponent(_endDate);
                    context.push(
                        '/report/list?startDate=$encodedStart&endDate=$encodedEnd');
                  },
                  child: Row(
                    children: [
                      Text(
                        'Lihat Detail',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primarySoft,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.primarySoft),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryRow(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.darkBlue)),
          Text(CurrencyFormatter.format(amount),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final String startDate;
  final String endDate;
  final String sign;
  final List<ReportCategoryItem> items;
  final Color chartColor;

  const _ChartSection({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.sign,
    required this.items,
    required this.chartColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue)),
          const Divider(height: 16),
          // Donut chart
          if (items.isNotEmpty)
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: items.take(8).map((item) {
                    Color c;
                    try {
                      final hex = item.categoryColor.replaceFirst('#', '');
                      c = Color(int.parse('FF$hex', radix: 16));
                    } catch (_) {
                      c = chartColor;
                    }
                    return PieChartSectionData(
                      value: item.totalAmount,
                      color: c,
                      radius: 60,
                      showTitle: false,
                    );
                  }).toList(),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(),
          GestureDetector(
            onTap: () {
              final encodedSign = Uri.encodeQueryComponent(sign);
              final encodedStart = Uri.encodeQueryComponent(startDate);
              final encodedEnd = Uri.encodeQueryComponent(endDate);
              context.push(
                  '/report/category?startDate=$encodedStart&endDate=$encodedEnd&sign=$encodedSign');
            },
            child: Row(
              children: [
                Text(
                  'Lihat Detail',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primarySoft,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: AppColors.primarySoft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final _DateRangeMode currentMode;

  const _FilterSheet({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    final options = [
      (_DateRangeMode.semua, 'Semua'),
      (_DateRangeMode.harian, 'Harian'),
      (_DateRangeMode.bulanan, 'Bulanan'),
      (_DateRangeMode.tahunan, 'Tahunan'),
      (_DateRangeMode.custom, 'Sesuaikan'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Rentang Waktu',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final (mode, label) = opt;
              return ChoiceChip(
                label: Text(label),
                selected: mode == currentMode,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: mode == currentMode ? Colors.white : AppColors.darkBlue,
                ),
                onSelected: (_) => Navigator.pop(context, mode),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
