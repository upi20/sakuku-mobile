import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class MainPage extends StatefulWidget {
  final Widget child;
  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Tab order matches the original app:
  // 0: Transaksi (History), 1: Laporan (Report), FAB, 2: Hutang (Debt), 3: Pengaturan (Settings)
  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Transaksi',
      icon: Icons.history,
      route: '/history',
    ),
    _TabItem(
      label: 'Laporan',
      icon: Icons.bar_chart,
      route: '/report',
    ),
    _TabItem(
      label: 'Hutang',
      icon: Icons.credit_card,
      route: '/debt',
    ),
    _TabItem(
      label: 'Pengaturan',
      icon: Icons.settings,
      route: '/settings',
    ),
  ];

  int get _currentIndex {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/report')) return 1;
    if (location.startsWith('/debt')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // default: history
  }

  void _onTap(int index) {
    context.go(_tabs[index].route);
  }

  void _onFabTap() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MainBottomSheet(
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

    return Scaffold(
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTap,
        backgroundColor: AppColors.primarySoft,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left 2 tabs
            _BottomNavItem(
              label: _tabs[0].label,
              icon: _tabs[0].icon,
              isActive: currentIndex == 0,
              onTap: () => _onTap(0),
            ),
            _BottomNavItem(
              label: _tabs[1].label,
              icon: _tabs[1].icon,
              isActive: currentIndex == 1,
              onTap: () => _onTap(1),
            ),
            // Space for FAB
            const SizedBox(width: 56),
            // Right 2 tabs
            _BottomNavItem(
              label: _tabs[2].label,
              icon: _tabs[2].icon,
              isActive: currentIndex == 2,
              onTap: () => _onTap(2),
            ),
            _BottomNavItem(
              label: _tabs[3].label,
              icon: _tabs[3].icon,
              isActive: currentIndex == 3,
              onTap: () => _onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ─────────────────────────────────────────────────────────────

class _TabItem {
  final String label;
  final IconData icon;
  final String route;
  const _TabItem({required this.label, required this.icon, required this.route});
}

// ─── Bottom Nav Item Widget ──────────────────────────────────────────────────

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primarySoft : AppColors.disabled;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB Bottom Sheet ────────────────────────────────────────────────────────

class _MainBottomSheet extends StatelessWidget {
  final VoidCallback onAddTransaction;
  final VoidCallback onAddTransfer;
  final VoidCallback onAddDebt;

  const _MainBottomSheet({
    required this.onAddTransaction,
    required this.onAddTransfer,
    required this.onAddDebt,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetItem(
              icon: Icons.receipt_long,
              label: AppStrings.addTransaction,
              onTap: onAddTransaction,
            ),
            _SheetItem(
              icon: Icons.swap_horiz,
              label: 'Transfer Saldo',
              onTap: onAddTransfer,
            ),
            _SheetItem(
              icon: Icons.credit_card,
              label: 'Hutang / Piutang',
              onTap: onAddDebt,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.darkBlue,
        ),
      ),
      onTap: onTap,
    );
  }
}
