import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/local/debt_repository.dart';
import '../../../core/models/debt_model.dart';
import '../../../shared/utils/currency_formatter.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutang & Piutang'),
        elevation: 0,
      ),
      body: const _DebtOverviewBody(),
    );
  }
}

class _DebtOverviewBody extends StatefulWidget {
  const _DebtOverviewBody();

  @override
  State<_DebtOverviewBody> createState() => _DebtOverviewBodyState();
}

class _DebtOverviewBodyState extends State<_DebtOverviewBody> {
  final _repo = DebtRepository();
  List<DebtModel> _hutangList = [];
  List<DebtModel> _piutangList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final hutang = await _repo.getAll(type: 1, isRelief: false);
      final piutang = await _repo.getAll(type: 2, isRelief: false);
      if (mounted) {
        setState(() {
          _hutangList = hutang;
          _piutangList = piutang;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _totalRemaining(List<DebtModel> list) =>
      list.fold(0, (sum, d) => sum + d.remainingAmount);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            label: 'HUTANG',
            subtitle: 'Saya berhutang kepada orang lain',
            icon: Icons.credit_card,
            iconColor: AppTheme.expense,
            count: _hutangList.length,
            totalRemaining: _totalRemaining(_hutangList),
            onTap: () async {
              await context.push('/debt/hutang');
              _load();
            },
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            label: 'PIUTANG',
            subtitle: 'Orang lain berhutang kepada saya',
            icon: Icons.monetization_on,
            iconColor: AppTheme.income,
            count: _piutangList.length,
            totalRemaining: _totalRemaining(_piutangList),
            onTap: () async {
              await context.push('/debt/piutang');
              _load();
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int count;
  final double totalRemaining;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.totalRemaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.cs.onSurfaceVariant)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: context.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$count belum lunas',
                      style: TextStyle(
                          fontSize: 12, color: context.cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalRemaining),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: iconColor),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
