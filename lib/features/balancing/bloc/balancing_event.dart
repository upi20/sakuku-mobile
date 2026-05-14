part of 'balancing_bloc.dart';

abstract class BalancingEvent extends Equatable {
  const BalancingEvent();

  @override
  List<Object?> get props => [];
}

/// Muat semua rekening aktif + saldo aplikasi dari DB.
class BalancingLoad extends BalancingEvent {
  const BalancingLoad();
}

/// User mengubah nilai "Sekarang" pada rekening tertentu di Halaman 1.
class BalancingRealBalanceChanged extends BalancingEvent {
  final int accountId;
  final double amount;

  const BalancingRealBalanceChanged(this.accountId, this.amount);

  @override
  List<Object?> get props => [accountId, amount];
}

/// User memilih total dari denomination sheet untuk rekening tertentu.
class BalancingDenominationUsed extends BalancingEvent {
  final int accountId;
  final double total;

  const BalancingDenominationUsed(this.accountId, this.total);

  @override
  List<Object?> get props => [accountId, total];
}

/// Tambah baris kosong di daftar transaksi bulk (Halaman 2).
class BalancingAddBulkEntry extends BalancingEvent {
  const BalancingAddBulkEntry();
}

/// Hapus baris pada indeks tertentu.
class BalancingRemoveBulkEntry extends BalancingEvent {
  final int index;

  const BalancingRemoveBulkEntry(this.index);

  @override
  List<Object?> get props => [index];
}

/// Update data baris pada indeks tertentu.
class BalancingUpdateBulkEntry extends BalancingEvent {
  final int index;
  final BulkTransactionEntry entry;

  const BalancingUpdateBulkEntry(this.index, this.entry);

  @override
  List<Object?> get props => [index, entry];
}

/// User memilih rekening balancing (hub) di Halaman 3.
class BalancingSelectAccount extends BalancingEvent {
  final int accountId;

  const BalancingSelectAccount(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

/// Eksekusi: buat transfer antar rekening + transaksi bulk.
class BalancingSave extends BalancingEvent {
  const BalancingSave();
}
