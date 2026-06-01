import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/quick_actions_service.dart';
import '../../core/theme/app_theme.dart';
import '../history/bloc/history_bloc.dart';
import '../history/view/quick_ai_sheet.dart';

class MainPage extends StatefulWidget {
  final Widget child;
  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _slidingForward = true;
  bool _isAiSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      QuickActionsService.instance.registerHandler(_handleShortcut);
    });
  }

  @override
  void dispose() {
    QuickActionsService.instance.clearHandler();
    super.dispose();
  }

  void _handleShortcut(String type) {
    if (!mounted) return;
    if (type == QuickActionsService.shortcutQuickAi) {
      if (_isAiSheetOpen) return;
      _onAiFabTap();
    }
  }

  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Dashboard',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
      route: '/dashboard',
    ),
    _TabItem(
      label: 'Transaksi',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      route: '/history',
    ),
    _TabItem(
      label: 'Laporan',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      route: '/report',
    ),
    _TabItem(
      label: 'Hutang',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
      route: '/debt',
    ),
    _TabItem(
      label: 'Pengaturan',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: '/settings',
    ),
  ];

  int get _currentIndex {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/report')) return 2;
    if (location.startsWith('/debt')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0; // /dashboard
  }

  void _onTap(int index) {
    final curr = _currentIndex;
    if (index == curr) return;
    setState(() {
      _slidingForward = index > curr;
    });
    if (index == 1) {
      final bloc = context.read<HistoryBloc>();
      if (bloc.state is! HistoryInitial) {
        bloc.add(HistoryRefresh());
      }
    }
    context.go(_tabs[index].route);
  }

  Future<void> _onAiFabTap() async {
    setState(() => _isAiSheetOpen = true);
    await showQuickAiSheet(context);
    if (mounted) setState(() => _isAiSheetOpen = false);
  }

  void _onFabTap() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AddActionSheet(
        onAddTransaction: () {
          Navigator.pop(context);
          context.push('/history/add');
        },
        onAddTransfer: () {
          Navigator.pop(context);
          context.push('/history/transfer/add');
        },
        onAddDebt: () {
          Navigator.pop(context);
          context.push('/debt/add?type=1');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final isDashboard = currentIndex == 0;
    return Scaffold(
      body: _SlidingBody(
        currentIndex: currentIndex,
        slidingForward: _slidingForward,
        child: widget.child,
      ),
      floatingActionButton: _isAiSheetOpen
          ? null
          : isDashboard
          ? FloatingActionButton(
              heroTag: 'ai_fab_dashboard',
              onPressed: _onAiFabTap,
              tooltip: 'Input AI',
              child: const Icon(Icons.auto_awesome, size: 30),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentIndex == 1) ...[
                  FloatingActionButton.small(
                    heroTag: 'ai_fab',
                    onPressed: _onAiFabTap,
                    tooltip: 'Input AI',
                    child: const Icon(Icons.auto_awesome),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton(
                  heroTag: 'add_fab',
                  onPressed: _onFabTap,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isDashboard
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: _onTap,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.selectedIcon),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ─── Sliding tab body ────────────────────────────────────────────────────────

class _SlidingBody extends StatelessWidget {
  final int currentIndex;
  final bool slidingForward;
  final Widget child;

  const _SlidingBody({
    required this.currentIndex,
    required this.slidingForward,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final enterOffset = slidingForward
            ? const Offset(0.25, 0)
            : const Offset(-0.25, 0);
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: enterOffset, end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(currentIndex), child: child),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

// ─── Add Action Bottom Sheet ─────────────────────────────────────────────────

class _AddActionSheet extends StatelessWidget {
  final VoidCallback onAddTransaction;
  final VoidCallback onAddTransfer;
  final VoidCallback onAddDebt;

  const _AddActionSheet({
    required this.onAddTransaction,
    required this.onAddTransfer,
    required this.onAddDebt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Tambah Baru',
                style: context.tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(
                  Icons.receipt_long,
                  color: cs.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(AppStrings.addTransaction),
              subtitle: const Text('Catat pemasukan atau pengeluaran'),
              onTap: onAddTransaction,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(
                  Icons.swap_horiz,
                  color: cs.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: const Text('Transfer Saldo'),
              subtitle: const Text('Pindahkan saldo antar rekening'),
              onTap: onAddTransfer,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.tertiaryContainer,
                child: Icon(
                  Icons.credit_card,
                  color: cs.onTertiaryContainer,
                  size: 20,
                ),
              ),
              title: const Text('Hutang / Piutang'),
              subtitle: const Text('Catat hutang atau piutang'),
              onTap: onAddDebt,
            ),
          ],
        ),
      ),
    );
  }
}
