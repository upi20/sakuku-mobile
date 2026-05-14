import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/account_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountBloc()..add(const AccountLoad()),
      child: const _AccountBody(),
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Rekening'),
        elevation: 0,
      ),
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AccountError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.expense,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AccountLoading || state is AccountInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AccountLoaded) {
            return _buildLoaded(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/settings/account/add');
          if (context.mounted) {
            context.read<AccountBloc>().add(const AccountLoad());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, AccountLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AccountBloc>().add(const AccountLoad());
      },
      child: CustomScrollView(
        slivers: [
          // Total balance header card (sesuai app lama: ic_account_all + "Total" + jumlah)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue)),
                      Text(
                        CurrencyFormatter.format(state.totalBalance),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.darkGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // List rekening atau empty state
          if (state.accounts.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: 'Belum ada rekening',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final acc = state.accounts[i];
                  return _AccountListItem(
                    account: acc,
                    balance: state.balanceOf(acc.id!),
                    onTap: () async {
                      await context.push(
                          '/settings/account/${acc.id}/edit');
                      if (context.mounted) {
                        context
                            .read<AccountBloc>()
                            .add(const AccountLoad());
                      }
                    },
                  );
                },
                childCount: state.accounts.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountListItem extends StatelessWidget {
  final AccountModel account;
  final double balance;
  final VoidCallback onTap;

  const _AccountListItem({
    required this.account,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(account.color);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          children: [
            // Icon bulat berwarna
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                AppIcons.fromName(account.icon),
                color: account.active == 1 ? color : AppColors.disabled,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: account.active == 1
                          ? AppColors.darkBlue
                          : AppColors.disabled,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.darkGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkGray),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
