import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/balancing_bloc.dart';
import 'balancing_check_page.dart';

/// Entry point fitur Balancing.
///
/// Bertanggung jawab mem-provide [BalancingBloc] agar dibagikan
/// ke seluruh sub-halaman (Check → Bulk → Confirm) yang di-push
/// via [Navigator.push]. BLoC tetap hidup selama [BalancingPage]
/// masih ada di stack navigasi.
class BalancingPage extends StatelessWidget {
  const BalancingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BalancingBloc()..add(const BalancingLoad()),
      child: const BalancingCheckPage(),
    );
  }
}
