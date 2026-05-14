part of 'balancing_bloc.dart';

abstract class BalancingState extends Equatable {
  const BalancingState();

  @override
  List<Object?> get props => [];
}

class BalancingInitial extends BalancingState {
  const BalancingInitial();
}

class BalancingLoading extends BalancingState {
  const BalancingLoading();
}

class BalancingLoaded extends BalancingState {
  final List<BalancingItem> items;
  final List<BulkTransactionEntry> bulkEntries;
  final int? balancingAccountId;

  const BalancingLoaded({
    required this.items,
    this.bulkEntries = const [],
    this.balancingAccountId,
  });

  // ── Computed totals ──────────────────────────────────────────

  double get totalAppBalance =>
      items.fold(0.0, (s, e) => s + e.appBalance);

  double get totalRealBalance =>
      items.fold(0.0, (s, e) => s + e.realBalance);

  /// Total selisih keseluruhan = totalReal − totalApp
  double get totalSelisih => totalRealBalance - totalAppBalance;

  /// Total nominal yang diinput di bulk transaksi.
  double get totalBulk =>
      bulkEntries.fold(0.0, (s, e) => s + e.amount);

  /// Sisa yang belum dijelaskan oleh catatan transaksi.
  /// = abs(totalSelisih) − totalBulk
  /// 0 → pas; > 0 → masih kurang; < 0 → catatan melebihi selisih
  double get sisaSelisih => totalSelisih.abs() - totalBulk;

  /// Rekening yang memerlukan transfer (selisih ≠ 0 dan bukan rekening balancing).
  List<BalancingItem> get transferItems => items.where((item) {
        if (item.isBalanced) { return false; }
        if (balancingAccountId != null &&
            item.account.id == balancingAccountId) { return false; }
        return true;
      }).toList();

  BalancingLoaded copyWith({
    List<BalancingItem>? items,
    List<BulkTransactionEntry>? bulkEntries,
    Object? balancingAccountId = _sentinel,
  }) {
    return BalancingLoaded(
      items: items ?? this.items,
      bulkEntries: bulkEntries ?? this.bulkEntries,
      balancingAccountId: balancingAccountId == _sentinel
          ? this.balancingAccountId
          : balancingAccountId as int?,
    );
  }

  @override
  List<Object?> get props => [items, bulkEntries, balancingAccountId];
}

/// Sedang menyimpan (proses eksekusi).
class BalancingSaving extends BalancingState {
  const BalancingSaving();
}

/// Simpan berhasil — semua transfer + bulk transaksi sudah dibuat.
class BalancingSaveSuccess extends BalancingState {
  const BalancingSaveSuccess();
}

class BalancingError extends BalancingState {
  final String message;

  const BalancingError(this.message);

  @override
  List<Object?> get props => [message];
}

// Sentinel untuk membedakan null yang disengaja vs tidak dikirim.
const Object _sentinel = Object();
