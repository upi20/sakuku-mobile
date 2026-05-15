import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../history/widgets/history_list_item.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

enum _DateRangeMode { semua, harian, bulanan, tahunan, custom }

class ReportAsListPage extends StatelessWidget {
  final String startDate;
  final String endDate;
  final int? categoryId;
  final String? categoryName;
  final String? sign;

  const ReportAsListPage({
    super.key,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.categoryName,
    this.sign,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportBloc()
        ..add(ReportLoadAsList(
            startDate: startDate,
            endDate: endDate,
            categoryId: categoryId,
            sign: sign)),
      child: _ReportAsListBody(
        initialStartDate: startDate,
        initialEndDate: endDate,
        categoryId: categoryId,
        categoryName: categoryName,
        initialSign: sign,
      ),
    );
  }
}

class _ReportAsListBody extends StatefulWidget {
  final String initialStartDate;
  final String initialEndDate;
  final int? categoryId;
  final String? categoryName;
  final String? initialSign;

  const _ReportAsListBody({
    required this.initialStartDate,
    required this.initialEndDate,
    this.categoryId,
    this.categoryName,
    this.initialSign,
  });

  @override
  State<_ReportAsListBody> createState() => _ReportAsListBodyState();
}

class _ReportAsListBodyState extends State<_ReportAsListBody> {
  late DateTime _current;
  late _DateRangeMode _mode;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _sign;

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
    context.read<ReportBloc>().add(ReportLoadAsList(
        startDate: _startDate,
        endDate: _endDate,
        categoryId: widget.categoryId,
        sign: _sign));
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

  void _setSign(String? sign) {
    setState(() => _sign = sign);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryName ?? 'Laporan List';
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
          // Navigasi waktu
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
          // Filter jenis transaksi
          Container(
            color: context.cs.surfaceContainerLowest,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                _SignChip(
                    label: 'Semua',
                    value: null,
                    current: _sign,
                    onTap: _setSign),
                const SizedBox(width: 6),
                _SignChip(
                    label: 'Pemasukan',
                    value: '+',
                    current: _sign,
                    onTap: _setSign),
                const SizedBox(width: 6),
                _SignChip(
                    label: 'Pengeluaran',
                    value: '-',
                    current: _sign,
                    onTap: _setSign),
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
                  if (state is ReportAsListLoaded) {
                    return _buildList(context, state);
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

  Widget _buildList(BuildContext context, ReportAsListLoaded state) {
    return ListView(
      children: [
        Container(
          color: context.cs.surfaceContainerLowest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(fontSize: 14, color: context.cs.onSurface)),
              Text(
                CurrencyFormatter.format(
                    state.totalIncome - state.totalExpense),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.cs.primary),
              ),
            ],
          ),
        ),
        if (state.histories.isEmpty)
          const SizedBox(
            height: 200,
            child: EmptyState(
              icon: Icons.history_outlined,
              message: 'Tidak ada transaksi',
            ),
          )
        else
          ...state.histories.map((h) => HistoryListItem(
                item: h,
                onTap: () => context.push('/history/${h.id}'),
              )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SignChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  final void Function(String?) onTap;

  const _SignChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.cs.primary : Colors.transparent,
          border: Border.all(
              color: selected ? context.cs.primary : context.cs.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? context.cs.onPrimary : context.cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
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

