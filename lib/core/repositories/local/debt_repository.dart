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
    // Hapus history awal debt lama (bukan dari trans), lalu update, lalu insert baru
    await _historyDao.deleteByDebtIdExcludingTrans(debt.id!);
    await _debtDao.update(debt);
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
