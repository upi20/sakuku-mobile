import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/pin_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Init database (copies from assets on first launch)
    await AppDatabase.instance.database;

    // Small delay for splash visibility
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final pinEnabled = await PinService.instance.isPinEnabled();

    if (!mounted) return;
    if (pinEnabled) {
      context.go('/pin/check');
    } else {
      context.go('/history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cs.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.cs.onPrimary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 56,
                color: context.cs.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: TextStyle(
                color: context.cs.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
