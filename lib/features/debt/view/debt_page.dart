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

    final hutangTotal = _totalRemaining(_hutangList);
    final piutangTotal = _totalRemaining(_piutangList);
    final net = piutangTotal - hutangTotal;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _HeroCard(
            label: 'HUTANG',
            subtitle: 'Saya berhutang kepada orang lain',
            icon: Icons.credit_card_outlined,
            color: AppTheme.expense,
            count: _hutangList.length,
            totalRemaining: hutangTotal,
            onTap: () async {
              await context.push('/debt/hutang');
              _load();
            },
          ),
          const SizedBox(height: 16),
          _HeroCard(
            label: 'PIUTANG',
            subtitle: 'Orang lain berhutang kepada saya',
            icon: Icons.payments_outlined,
            color: AppTheme.income,
            count: _piutangList.length,
            totalRemaining: piutangTotal,
            onTap: () async {
              await context.push('/debt/piutang');
              _load();
            },
          ),
          const SizedBox(height: 20),
          _NetBalanceCard(net: net),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final double totalRemaining;
  final VoidCallback onTap;

  const _HeroCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.count,
    required this.totalRemaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero zone (colored background) ──────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: color.withValues(alpha: 0.1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.tt.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatCompact(totalRemaining),
                          style: context.tt.headlineSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count belum lunas',
                          style: context.tt.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Detail zone (surface) ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: context.tt.bodySmall?.copyWith(
                        color: context.cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lihat',
                    style: context.tt.labelMedium?.copyWith(
                      color: context.cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: context.cs.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetBalanceCard extends StatelessWidget {
  final double net;

  const _NetBalanceCard({required this.net});

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    final color = isPositive ? AppTheme.income : AppTheme.expense;
    final label = isPositive
        ? 'Orang lain masih berhutang kepada Anda'
        : 'Anda masih berhutang kepada orang lain';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 20,
            color: context.cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET SALDO',
                  style: context.tt.labelSmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.formatCompact(net.abs()),
            style: context.tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
