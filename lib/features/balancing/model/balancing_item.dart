import '../../../core/models/account_model.dart';

class BalancingItem {
  final AccountModel account;
  final double appBalance;
  final double realBalance;

  const BalancingItem({
    required this.account,
    required this.appBalance,
    this.realBalance = 0,
  });

  /// True jika rekening ini adalah rekening tunai / dompet fisik.
  /// Deteksi berdasarkan icon atau nama rekening.
  bool get isDenominationEligible {
    final icon = account.icon.toLowerCase();
    final name = account.name.toUpperCase();
    return icon == 'ic_cash' ||
        name.contains('DOMPET') ||
        name.contains('TUNAI') ||
        name.contains('CASH');
  }

  /// Selisih = Sekarang (real) − Aplikasi
  /// < 0 → app > real → transfer FROM rekening ini TO balancing
  /// > 0 → real > app → transfer FROM balancing TO rekening ini
  /// = 0 → tidak perlu transfer
  double get selisih => realBalance - appBalance;

  bool get isBalanced => selisih == 0;

  /// Saldo aplikasi lebih tinggi dari nyata → harus kirim ke balancing
  bool get isAppHigher => selisih < 0;

  /// Saldo nyata lebih tinggi dari aplikasi → balancing kirim ke sini
  bool get isRealHigher => selisih > 0;

  BalancingItem copyWith({
    AccountModel? account,
    double? appBalance,
    double? realBalance,
  }) {
    return BalancingItem(
      account: account ?? this.account,
      appBalance: appBalance ?? this.appBalance,
      realBalance: realBalance ?? this.realBalance,
    );
  }
}
