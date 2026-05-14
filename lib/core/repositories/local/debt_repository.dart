import '../../database/daos/debt_dao.dart';
import '../../database/daos/debt_trans_dao.dart';
import '../../database/daos/history_dao.dart';
import '../../models/debt_model.dart';
import '../../models/debt_trans_model.dart';
import '../../models/history_model.dart';
import '../interfaces/i_debt_repository.dart';

class DebtRepository implements IDebtRepository {
  final DebtDao _debtDao;
  final DebtTransDao _transDao;
  final HistoryDao _historyDao;

  DebtRepository({DebtDao? debtDao, DebtTransDao? transDao, HistoryDao? historyDao})
      : _debtDao = debtDao ?? DebtDao(),
        _transDao = transDao ?? DebtTransDao(),
        _historyDao = historyDao ?? HistoryDao();

  @override
  Future<List<DebtModel>> getAll({int? type, bool? isRelief}) =>
      _debtDao.getAll(type: type, isRelief: isRelief);

  @override
  Future<DebtModel?> getById(int id) => _debtDao.getById(id);

  @override
  Future<int> createDebt(DebtModel debt) async {
    final debtId = await _debtDao.insert(debt);
    // type==1 hutang (pinjam uang, masuk ke rekening → '+')
    // type==2 piutang (kasih pinjaman, keluar dari rekening → '-')
    final categoryId = debt.type == 1 ? 4 : 6;
    final sign = debt.type == 1 ? '+' : '-';
    final dateOnly = debt.startDateTime.length >= 10
        ? debt.startDateTime.substring(0, 10)
        : debt.startDateTime;
    final timeOnly = debt.startDateTime.length >= 16
        ? debt.startDateTime.substring(11, 16)
        : '00:00';
    await _historyDao.insert(HistoryModel(
      categoryId: categoryId,
      accountId: debt.accountId,
      transferId: 0,
      type: 3,
      amount: debt.amount,
      date: dateOnly,
      time: timeOnly,
      dateTime: debt.startDateTime,
      note: debt.note,
      sign: sign,
      debtId: debtId,
      debtTransId: 0,
    ));
    return debtId;
  }

  @override
  Future<int> updateDebt(DebtModel debt) async {
    // Hapus SEMUA history terkait debt ini (termasuk dari trans)
    // agar jika type berubah hutang↔piutang semua sign & category ter-rebuild
    await _historyDao.deleteByDebtId(debt.id!);

    // Ambil semua trans sebelum update (karena kita perlu rebuild historynya)
    final existingTrans = await _transDao.getByDebtId(debt.id!);

    await _debtDao.update(debt);

    // Re-insert history awal debt
    final categoryId = debt.type == 1 ? 4 : 6;
    final sign = debt.type == 1 ? '+' : '-';
    final dateOnly = debt.startDateTime.length >= 10
        ? debt.startDateTime.substring(0, 10)
        : debt.startDateTime;
    final timeOnly = debt.startDateTime.length >= 16
        ? debt.startDateTime.substring(11, 16)
        : '00:00';
    await _historyDao.insert(HistoryModel(
      categoryId: categoryId,
      accountId: debt.accountId,
      transferId: 0,
      type: 3,
      amount: debt.amount,
      date: dateOnly,
      time: timeOnly,
      dateTime: debt.startDateTime,
      note: debt.note,
      sign: sign,
      debtId: debt.id!,
      debtTransId: 0,
    ));

    // Re-insert history untuk setiap trans yang sudah ada, pakai type debt baru
    for (final t in existingTrans) {
      final int transCatId;
      final String transSign;
      if (debt.type == 1) {
        // hutang: pembayaran(1)→cat=7,'-' | penambahan(2)→cat=9,'+'
        if (t.type == 1) { transCatId = 7; transSign = '-'; }
        else { transCatId = 9; transSign = '+'; }
      } else {
        // piutang: pembayaran(1)→cat=5,'+' | penambahan(2)→cat=10,'-'
        if (t.type == 1) { transCatId = 5; transSign = '+'; }
        else { transCatId = 10; transSign = '-'; }
      }
      final tDateOnly = t.dateTime.length >= 10 ? t.dateTime.substring(0, 10) : t.dateTime;
      final tTimeOnly = t.dateTime.length >= 16 ? t.dateTime.substring(11, 16) : '00:00';
      await _historyDao.insert(HistoryModel(
        categoryId: transCatId,
        accountId: t.accountId,
        transferId: 0,
        type: 5,
        amount: t.amount,
        date: tDateOnly,
        time: tTimeOnly,
        dateTime: t.dateTime,
        note: t.note,
        sign: transSign,
        debtId: debt.id!,
        debtTransId: t.id!,
      ));
    }

    return debt.id!;
  }

  @override
  Future<int> deleteDebt(int id) async {
    // Hapus semua history terkait debt ini (termasuk yang dari trans)
    await _historyDao.deleteByDebtId(id);
    return _debtDao.delete(id);
  }

  @override
  Future<List<DebtTransModel>> getTransactions(int debtId) =>
      _transDao.getByDebtId(debtId);

  @override
  Future<int> createTransaction(DebtTransModel trans) async {
    final transId = await _transDao.insert(trans);
    final parentDebt = await _debtDao.getById(trans.debtId);
    if (parentDebt == null) return transId;

    // Mapping (debtType, transType) → (categoryId, sign)
    // hutang(1)+pembayaran(1): bayar kembali → uang keluar → '-', cat=7  (Bayar Hutang)
    // hutang(1)+penambahan(2): pinjam lebih → uang masuk → '+', cat=9  (Tambah Hutang)
    // piutang(2)+pembayaran(1): terima pembayaran → uang masuk → '+', cat=5  (Tagih Hutang)
    // piutang(2)+penambahan(2): kasih pinjaman lebih → uang keluar → '-', cat=10 (Tambah Pinjaman)
    final int categoryId;
    final String sign;
    if (parentDebt.type == 1) {
      if (trans.type == 1) {
        categoryId = 7;
        sign = '-';
      } else {
        categoryId = 9;
        sign = '+';
      }
    } else {
      if (trans.type == 1) {
        categoryId = 5;
        sign = '+';
      } else {
        categoryId = 10;
        sign = '-';
      }
    }

    final dateOnly = trans.dateTime.length >= 10
        ? trans.dateTime.substring(0, 10)
        : trans.dateTime;
    final timeOnly = trans.dateTime.length >= 16
        ? trans.dateTime.substring(11, 16)
        : '00:00';
    await _historyDao.insert(HistoryModel(
      categoryId: categoryId,
      accountId: trans.accountId,
      transferId: 0,
      type: 5,
      amount: trans.amount,
      date: dateOnly,
      time: timeOnly,
      dateTime: trans.dateTime,
      note: trans.note,
      sign: sign,
      debtId: trans.debtId,
      debtTransId: transId,
    ));
    return transId;
  }

  @override
  Future<int> updateTransaction(DebtTransModel trans) async {
    // Hapus history lama berdasarkan debtTransId, update trans, insert history baru
    await _historyDao.deleteByDebtTransId(trans.id!);
    await _transDao.update(trans);
    final parentDebt = await _debtDao.getById(trans.debtId);
    if (parentDebt == null) return trans.id!;

    // hutang(1)+pembayaran(1): cat=7 (Bayar Hutang), sign='-'
    // hutang(1)+penambahan(2): cat=9 (Tambah Hutang), sign='+'
    // piutang(2)+pembayaran(1): cat=5 (Tagih Hutang), sign='+'
    // piutang(2)+penambahan(2): cat=10 (Tambah Pinjaman), sign='-'
    final int categoryId;
    final String sign;
    if (parentDebt.type == 1) {
      if (trans.type == 1) {
        categoryId = 7;
        sign = '-';
      } else {
        categoryId = 9;
        sign = '+';
      }
    } else {
      if (trans.type == 1) {
        categoryId = 5;
        sign = '+';
      } else {
        categoryId = 10;
        sign = '-';
      }
    }

    final dateOnly = trans.dateTime.length >= 10
        ? trans.dateTime.substring(0, 10)
        : trans.dateTime;
    final timeOnly = trans.dateTime.length >= 16
        ? trans.dateTime.substring(11, 16)
        : '00:00';
    await _historyDao.insert(HistoryModel(
      categoryId: categoryId,
      accountId: trans.accountId,
      transferId: 0,
      type: 5,
      amount: trans.amount,
      date: dateOnly,
      time: timeOnly,
      dateTime: trans.dateTime,
      note: trans.note,
      sign: sign,
      debtId: trans.debtId,
      debtTransId: trans.id!,
    ));
    return trans.id!;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    // Hapus history terkait debt trans ini sebelum delete
    await _historyDao.deleteByDebtTransId(id);
    return _transDao.delete(id);
  }
}
