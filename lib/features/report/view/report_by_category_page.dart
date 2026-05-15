import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

enum _DateRangeMode { semua, harian, bulanan, tahunan, custom }

class ReportByCategoryPage extends StatelessWidget {
  final String startDate;
  final String endDate;
  final String sign;

  const ReportByCategoryPage({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.sign,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportBloc()
        ..add(ReportLoadByCategory(
            startDate: startDate, endDate: endDate, sign: sign)),
      child: _ReportByCategoryBody(
          initialStartDate: startDate,
          initialEndDate: endDate,
          initialSign: sign),
    );
  }
}

class _ReportByCategoryBody extends StatefulWidget {
  final String initialStartDate;
  final String initialEndDate;
  final String initialSign;

  const _ReportByCategoryBody(
      {required this.initialStartDate,
      required this.initialEndDate,
      required this.initialSign});

  @override
  State<_ReportByCategoryBody> createState() => _ReportByCategoryBodyState();
}

class _ReportByCategoryBodyState extends State<_ReportByCategoryBody> {
  late DateTime _current;
  late String _sign;
  late _DateRangeMode _mode;
  DateTime? _customStart;
  DateTime? _customEnd;

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static _DateRangeMode _inferMode(String start, String end) {
    if (start == '2000-01-01') return _DateRangeMode.semua;
    if (start == end) return _DateRangeMode.harian;
    if (start.length >= 10 && end.length >= 10) {
      final sy = start.substring(0, 4);
      final ey = end.substring(0, 4);
      if (sy == ey &&
          start.substring(5) == '01-01' &&
          end.substring(5) == '12-31') {
        return _DateRangeMode.tahunan;
      }
      if (start.substring(0, 7) == end.substring(0, 7) &&
          start.substring(8) == '01') {
        return _DateRangeMode.bulanan;
      }
    }
    return _DateRangeMode.custom;
  }

  @override
  void initState() {
    super.initState();
    _mode = _inferMode(widget.initialStartDate, widget.initialEndDate);
    final parts = widget.initialStartDate.split('-');
    _current = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    _sign = widget.initialSign;
    if (_mode == _DateRangeMode.custom) {
      _customStart = DateTime.tryParse(widget.initialStartDate);
      _customEnd = DateTime.tryParse(widget.initialEndDate);
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
          return '${_fmt(_customStart!)} \u2014 ${_fmt(_customEnd!)}';
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
    });
    _reload();
  }

  void _reload() {
    context.read<ReportBloc>().add(ReportLoadByCategory(
        startDate: _startDate, endDate: _endDate, sign: _sign));
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
        });
        _reload();
      }
    } else {
      setState(() => _mode = result);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _sign == '+' ? 'Laporan Pendapatan' : 'Laporan Pengeluaran';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter rentang waktu',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: context.cs.surfaceContainerLowest,
            child: Row(
              children: [
                if (_canNavigate)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _prev,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    _currentLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.cs.onSurface),
                  ),
                ),
                if (_canNavigate)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _next,
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state is ReportLoading || state is ReportInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ReportByCategoryLoaded) {
                    return _buildList(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ReportByCategoryLoaded state) {
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.assessment_outlined,
        message: 'Tidak ada laporan',
      );
    }

    final amountColor = _sign == '+' ? AppTheme.income : AppTheme.expense;

    return ListView(
      children: [
        Container(
          color: context.cs.surfaceContainerLowest,
          padding: const EdgeInsets.symmetric(vertical: 16),
          margin: const EdgeInsets.only(bottom: 2),
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sections: state.items.take(8).map((item) {
                      Color c;
                      try {
                        final hex = item.categoryColor.replaceFirst('#', '');
                        c = Color(int.parse('FF$hex', radix: 16));
                      } catch (_) {
                        c = amountColor;
                      }
                      return PieChartSectionData(
                        value: item.totalAmount,
                        color: c,
                        radius: 70,
                        showTitle: false,
                      );
                    }).toList(),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Total',
                  style: TextStyle(fontSize: 12)),
              Text(
                CurrencyFormatter.format(state.total),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor),
              ),
            ],
          ),
        ),
        ...state.items.map((item) => _CategoryReportItem(
              item: item,
              amountColor: amountColor,
              startDate: _startDate,
              endDate: _endDate,
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CategoryReportItem extends StatelessWidget {
  final ReportCategoryItem item;
  final Color amountColor;
  final String startDate;
  final String endDate;

  const _CategoryReportItem({
    required this.item,
    required this.amountColor,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    try {
      final hex = item.categoryColor.replaceFirst('#', '');
      iconColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      iconColor = context.cs.onSurfaceVariant;
    }

    final pct = (item.percentage * 100).toStringAsFixed(1);

    return InkWell(
      onTap: () {
        final encodedSign = Uri.encodeQueryComponent(item.sign);
        final encodedName = Uri.encodeQueryComponent(item.categoryName);
        final encodedStart = Uri.encodeQueryComponent(startDate);
        final encodedEnd = Uri.encodeQueryComponent(endDate);
        context.push(
          '/report/list?startDate=$encodedStart&endDate=$encodedEnd'
          '&categoryId=${item.categoryId}&categoryName=$encodedName&sign=$encodedSign',
        );
      },
      child: Container(
        color: context.cs.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(AppIcons.fromName(item.categoryIcon),
                  color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.cs.onSurface),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.totalAmount),
                        style: TextStyle(fontSize: 13, color: amountColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$pct%',
                          style: TextStyle(
                              fontSize: 11, color: context.cs.onSurfaceVariant)),
                      Text('${item.totalCount}x',
                          style: TextStyle(
                              fontSize: 11, color: context.cs.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.percentage.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: context.cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(amountColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
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
          const Text('Filter Rentang Waktu',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final (mode, label) = opt;
              return ChoiceChip(
                label: Text(label),
                selected: mode == currentMode,
                onSelected: (_) => Navigator.pop(context, mode),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
