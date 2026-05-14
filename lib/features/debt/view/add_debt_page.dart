import 'package:flutter/material.dart';

class AddDebtPage extends StatelessWidget {
  final int? debtType; // 1=hutang, 2=piutang
  const AddDebtPage({super.key, this.debtType});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Tambah Hutang')),
    );
  }
}
