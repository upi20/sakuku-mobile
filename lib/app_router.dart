import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/utils/pin_service.dart';
import 'features/splash/splash_page.dart';
import 'features/main/main_page.dart';
import 'features/pin/view/check_pin_page.dart';
import 'features/history/view/history_page.dart';
import 'features/history/view/history_detail_page.dart';
import 'features/history/view/add_history_page.dart';
import 'features/history/view/edit_history_page.dart';
import 'features/history/view/add_transfer_page.dart';
import 'features/history/view/edit_transfer_page.dart';
import 'features/history/view/transfer_detail_page.dart';
import 'features/history/view/filter_history_page.dart';
import 'features/history/view/search_history_page.dart';
import 'features/report/view/report_page.dart';
import 'features/debt/view/debt_page.dart';
import 'features/debt/view/add_debt_page.dart';
import 'features/settings/view/settings_page.dart';
import 'features/account/view/account_page.dart';
import 'features/account/view/add_account_page.dart';
import 'features/account/view/edit_account_page.dart';
import 'features/category/view/category_page.dart';
import 'features/category/view/add_category_page.dart';
import 'features/category/view/edit_category_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── Splash ──────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (_, _) => const SplashPage(),
    ),

    // ── PIN Check ───────────────────────────────────────────────
    GoRoute(
      path: '/pin/check',
      name: 'pin-check',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const CheckPinPage(),
    ),

    // ── Main Shell (bottom nav) ──────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainPage(child: child),
      routes: [
        GoRoute(
          path: '/history',
          name: 'history',
          builder: (_, _) => const HistoryPage(),
        ),
        GoRoute(
          path: '/report',
          name: 'report',
          builder: (_, _) => const ReportPage(),
        ),
        GoRoute(
          path: '/debt',
          name: 'debt',
          builder: (_, _) => const DebtPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (_, _) => const SettingsPage(),
        ),
      ],
    ),

    // ── Full-screen routes (above nav) ───────────────────────────
    GoRoute(
      path: '/history/add',
      name: 'history-add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const AddHistoryPage(),
    ),
    GoRoute(
      path: '/history/search',
      name: 'history-search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const SearchHistoryPage(),
    ),
    GoRoute(
      path: '/history/filter',
      name: 'history-filter',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const FilterHistoryPage(),
    ),
    GoRoute(
      path: '/history/transfer/add',
      name: 'transfer-add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const AddTransferPage(),
    ),
    GoRoute(
      path: '/history/transfer/:transferId',
      name: 'transfer-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['transferId']!);
        return TransferDetailPage(transferId: id);
      },
    ),
    GoRoute(
      path: '/history/transfer/:transferId/edit',
      name: 'transfer-edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['transferId']!);
        return EditTransferPage(transferId: id);
      },
    ),
    GoRoute(
      path: '/history/:historyId',
      name: 'history-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['historyId']!);
        return HistoryDetailPage(historyId: id);
      },
    ),
    GoRoute(
      path: '/history/:historyId/edit',
      name: 'history-edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['historyId']!);
        return EditHistoryPage(historyId: id);
      },
    ),
    GoRoute(
      path: '/debt/add',
      name: 'debt-add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final type = int.tryParse(
          state.uri.queryParameters['type'] ?? '1',
        );
        return AddDebtPage(debtType: type);
      },
    ),

    // ── Account routes ───────────────────────────────────────────
    GoRoute(
      path: '/settings/account',
      name: 'account',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const AccountPage(),
    ),
    GoRoute(
      path: '/settings/account/add',
      name: 'account-add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const AddAccountPage(),
    ),
    GoRoute(
      path: '/settings/account/:accountId/edit',
      name: 'account-edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['accountId']!);
        return EditAccountPage(accountId: id);
      },
    ),

    // ── Category routes ──────────────────────────────────────────
    GoRoute(
      path: '/settings/category',
      name: 'category',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const CategoryPage(),
    ),
    GoRoute(
      path: '/settings/category/add',
      name: 'category-add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sign = state.extra as String? ?? '+';
        return AddCategoryPage(initialSign: sign);
      },
    ),
    GoRoute(
      path: '/settings/category/:categoryId/edit',
      name: 'category-edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['categoryId']!);
        return EditCategoryPage(categoryId: id);
      },
    ),
  ],

  // ── PIN guard ────────────────────────────────────────────────
  redirect: (context, state) async {
    final location = state.matchedLocation;

    // Never redirect on splash or pin pages
    if (location == '/splash' || location == '/pin/check') return null;

    final pinEnabled = await PinService.instance.isPinEnabled();
    if (pinEnabled) return '/pin/check';

    return null;
  },
);
