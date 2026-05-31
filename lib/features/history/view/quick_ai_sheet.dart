import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/ai_transaction_service.dart';
import '../../../core/api/tts_service.dart';
import '../../../core/api/voice_input_service.dart';
import '../../../core/database/daos/history_transfer_dao.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/history_model.dart';
import '../../../core/models/history_transfer_model.dart';
import '../../../core/repositories/interfaces/i_account_repository.dart';
import '../../../core/repositories/interfaces/i_category_repository.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../bloc/add_history_bloc.dart';
import '../bloc/history_bloc.dart';

// Fixed system category IDs (mirror of TransferBloc constants).
const int _kCategorySrcTransfer = 1;   // Kirim Saldo (-)
const int _kCategoryDestTransfer = 2;  // Terima Saldo (+)
const int _kCategoryTransferFee = 3;   // Biaya Admin (-)

// ─── Entry point ─────────────────────────────────────────────────────────────

Future<void> showQuickAiSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<HistoryBloc>(),
      child: _QuickAiSheet(
        historyRepo: context.read<IHistoryRepository>(),
        categoryRepo: context.read<ICategoryRepository>(),
        accountRepo: context.read<IAccountRepository>(),
        transferDao: context.read<HistoryTransferDao>(),
      ),
    ),
  );
}

// ─── State machine ────────────────────────────────────────────────────────────

enum _Phase { loading, listening, processing, confirming, saving, error }

sealed class _ParsedResult {
  const _ParsedResult();
}

class _ParsedTx extends _ParsedResult {
  final String sign;
  final double amount;
  final String note;
  final CategoryModel category;
  final AccountModel account;

  const _ParsedTx({
    required this.sign,
    required this.amount,
    required this.note,
    required this.category,
    required this.account,
  });

  _ParsedTx copyWith({
    String? sign,
    double? amount,
    String? note,
    CategoryModel? category,
    AccountModel? account,
  }) {
    return _ParsedTx(
      sign: sign ?? this.sign,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      category: category ?? this.category,
      account: account ?? this.account,
    );
  }
}

class _ParsedTransfer extends _ParsedResult {
  final double amount;
  final double fee;
  final String note;
  final AccountModel from;
  final AccountModel to;
  final DateTime dateTime;

  /// True jika AI gagal mengidentifikasi salah satu rekening unik
  /// (auto-fallback ke rekening lain).
  final bool fallbackUsed;

  const _ParsedTransfer({
    required this.amount,
    required this.fee,
    required this.note,
    required this.from,
    required this.to,
    required this.dateTime,
    this.fallbackUsed = false,
  });

  _ParsedTransfer copyWith({
    double? amount,
    double? fee,
    String? note,
    AccountModel? from,
    AccountModel? to,
    DateTime? dateTime,
    bool? fallbackUsed,
  }) {
    return _ParsedTransfer(
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      note: note ?? this.note,
      from: from ?? this.from,
      to: to ?? this.to,
      dateTime: dateTime ?? this.dateTime,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
    );
  }
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _QuickAiSheet extends StatefulWidget {
  final IHistoryRepository historyRepo;
  final ICategoryRepository categoryRepo;
  final IAccountRepository accountRepo;
  final HistoryTransferDao transferDao;

  const _QuickAiSheet({
    required this.historyRepo,
    required this.categoryRepo,
    required this.accountRepo,
    required this.transferDao,
  });

  @override
  State<_QuickAiSheet> createState() => _QuickAiSheetState();
}

class _QuickAiSheetState extends State<_QuickAiSheet>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.loading;
  String _transcript = '';
  String _errorMsg = '';
  bool _permissionDenied = false;
  _ParsedResult? _result;

  List<CategoryModel> _allCategories = [];
  List<AccountModel> _allAccounts = [];

  // Utterance accumulation (same logic as _AiInputSheet)
  String _textBeforeListen = '';
  bool _lastResultWasNonEmpty = false;

  // Sound level (normalized 0..1) for mic ring scale
  double _soundLevel = 0.0;

  late final AnimationController _idlePulseCtrl;

  @override
  void initState() {
    super.initState();

    _idlePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _loadAndListen();
  }

  @override
  void dispose() {
    _idlePulseCtrl.dispose();
    VoiceInputService.instance.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  // ── Data loading + auto-start listening ────────────────────────────────────

  Future<void> _loadAndListen() async {
    try {
      final results = await Future.wait([
        widget.categoryRepo.getAll(activeOnly: true),
        widget.accountRepo.getAll(activeOnly: true),
      ]);
      _allCategories = results[0] as List<CategoryModel>;
      _allAccounts = results[1] as List<AccountModel>;
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = 'Gagal memuat data: $e';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _phase = _Phase.listening);
    await _startListening();
  }

  Future<void> _startListening() async {
    _textBeforeListen = '';
    _lastResultWasNonEmpty = false;
    _soundLevel = 0.0;
    await TtsService.instance.stop();
    try {
      await VoiceInputService.instance.startListening(
        onResult: (text) {
          if (!mounted) return;
          if (text.isNotEmpty) {
            final combined = _textBeforeListen.isEmpty
                ? text.trim()
                : '${_textBeforeListen} ${text.trim()}';
            _lastResultWasNonEmpty = true;
            setState(() => _transcript = combined);
          } else if (_lastResultWasNonEmpty) {
            _textBeforeListen = _transcript.trimRight();
            _lastResultWasNonEmpty = false;
          }
        },
        onSoundLevel: (level) {
          if (!mounted) return;
          // STT level umumnya -2..10 dB. Map ke 0..1 untuk skala visual.
          final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
          if ((normalized - _soundLevel).abs() > 0.02) {
            setState(() => _soundLevel = normalized);
          }
        },
        onDone: () {
          if (mounted && _phase == _Phase.listening) {
            _processTranscript();
          }
        },
      );
    } on MicPermissionDeniedException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _permissionDenied = true;
          _errorMsg = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _permissionDenied = false;
          _errorMsg = 'Gagal memulai mikrofon: $e';
        });
      }
    }
  }

  // ── Stop + process ──────────────────────────────────────────────────────────

  Future<void> _stopAndProcess() async {
    if (_phase != _Phase.listening) return;
    _textBeforeListen = _transcript.trimRight();
    await VoiceInputService.instance.stopListening();
    _processTranscript();
  }

  Future<void> _processTranscript() async {
    if (!mounted) return;
    final text = _transcript.trim();
    if (text.isEmpty) {
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Tidak ada suara yang terdeteksi.\nCoba lagi dan bicara lebih jelas.';
      });
      return;
    }

    setState(() => _phase = _Phase.processing);

    try {
      final parsed = await AiTransactionService.instance.parse(
        userInput: text,
        categories: _allCategories,
        accounts: _allAccounts,
      );

      final result = switch (parsed) {
        AiParsedTransaction p => _resolveTransaction(p),
        AiParsedTransfer p => _resolveTransfer(p),
      };

      // TTS confirmation
      switch (result) {
        case _ParsedTx tx:
          final typeText = tx.sign == '+' ? 'Pemasukan' : 'Pengeluaran';
          TtsService.instance.speak(
            '$typeText ${CurrencyFormatter.formatForSpeech(tx.amount)}, '
            '${tx.category.name}, ${tx.account.name}.',
          );
        case _ParsedTransfer tr:
          final feePart = tr.fee > 0
              ? ', biaya admin ${CurrencyFormatter.formatForSpeech(tr.fee)}'
              : '';
          TtsService.instance.speak(
            'Transfer ${CurrencyFormatter.formatForSpeech(tr.amount)} '
            'dari ${tr.from.name} ke ${tr.to.name}$feePart.',
          );
      }

      if (mounted) {
        setState(() {
          _phase = _Phase.confirming;
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = e.toString();
        });
      }
    }
  }

  // ── AI result resolvers ─────────────────────────────────────────────────────

  _ParsedTx _resolveTransaction(AiParsedTransaction p) {
    final filteredCats = _allCategories
        .where((c) => c.sign == p.sign && c.active == 1)
        .toList();
    final category = filteredCats.isEmpty
        ? _allCategories.first
        : filteredCats.firstWhere(
            (c) => c.name.toLowerCase() == p.categoryName.toLowerCase(),
            orElse: () => filteredCats.first,
          );

    final activeAccounts =
        _allAccounts.where((a) => a.active == 1).toList();
    final account = activeAccounts.isEmpty
        ? _allAccounts.first
        : activeAccounts.firstWhere(
            (a) => a.name.toLowerCase() == p.accountName.toLowerCase(),
            orElse: () => activeAccounts.first,
          );

    final amount = double.tryParse(p.amountText) ?? 0.0;
    return _ParsedTx(
      sign: p.sign,
      amount: amount,
      note: p.note,
      category: category,
      account: account,
    );
  }

  _ParsedTransfer _resolveTransfer(AiParsedTransfer p) {
    final active = _allAccounts.where((a) => a.active == 1).toList();
    if (active.length < 2) {
      throw Exception(
          'Transfer butuh minimal 2 rekening aktif. Saat ini hanya ${active.length}.');
    }

    AccountModel matchOr(String name, AccountModel fallback) {
      return active.firstWhere(
        (a) => a.name.toLowerCase() == name.toLowerCase(),
        orElse: () => fallback,
      );
    }

    var from = matchOr(p.fromAccountName, active.first);
    var to = matchOr(p.toAccountName, active.firstWhere(
      (a) => a.id != from.id,
      orElse: () => active.first,
    ));

    var fallbackUsed = from.name.toLowerCase() != p.fromAccountName.toLowerCase() ||
        to.name.toLowerCase() != p.toAccountName.toLowerCase();

    // Pastikan from != to
    if (from.id == to.id) {
      final alt = active.firstWhere(
        (a) => a.id != from.id,
        orElse: () => from,
      );
      if (alt.id == from.id) {
        throw Exception('Tidak bisa menentukan rekening tujuan berbeda.');
      }
      to = alt;
      fallbackUsed = true;
    }

    final amount = double.tryParse(p.amountText) ?? 0.0;
    final fee = double.tryParse(p.feeText) ?? 0.0;

    return _ParsedTransfer(
      amount: amount,
      fee: fee,
      note: p.note,
      from: from,
      to: to,
      dateTime: p.datetime ?? DateTime.now(),
      fallbackUsed: fallbackUsed,
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final r = _result;
    if (r == null) return;

    setState(() => _phase = _Phase.saving);

    try {
      switch (r) {
        case _ParsedTx tx:
          await _saveTransaction(tx);
        case _ParsedTransfer tr:
          await _saveTransfer(tr);
      }

      if (mounted) {
        context.read<HistoryBloc>().add(HistoryRefresh());
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = 'Gagal menyimpan: $e';
        });
      }
    }
  }

  Future<void> _saveTransaction(_ParsedTx r) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    final model = HistoryModel(
      categoryId: r.category.id!,
      accountId: r.account.id!,
      type: 1,
      amount: r.amount,
      date: dateStr,
      time: timeStr,
      dateTime: '$dateStr $timeStr',
      note: r.note,
      sign: r.sign,
    );

    await widget.historyRepo.create(model);
  }

  Future<void> _saveTransfer(_ParsedTransfer r) async {
    if (r.from.id == null || r.to.id == null) {
      throw Exception('Rekening belum lengkap.');
    }
    if (r.from.id == r.to.id) {
      throw Exception('Rekening asal dan tujuan harus berbeda.');
    }
    if (r.amount <= 0) {
      throw Exception('Nominal harus lebih dari nol.');
    }

    String two(int n) => n.toString().padLeft(2, '0');
    final dt = r.dateTime;
    final dateStr = '${dt.year}-${two(dt.month)}-${two(dt.day)}';
    final timeStr = '${two(dt.hour)}:${two(dt.minute)}:00';
    final dateTimeStr = '$dateStr $timeStr';

    final transfer = HistoryTransferModel(
      srcAccountId: r.from.id!,
      destAccountId: r.to.id!,
      amount: r.amount,
      date: dateStr,
      time: timeStr,
      datetime: dateTimeStr,
    );
    final transferId = await widget.transferDao.insert(transfer);

    await widget.historyRepo.create(HistoryModel(
      categoryId: _kCategorySrcTransfer,
      accountId: r.from.id!,
      transferId: transferId,
      type: 2,
      amount: r.amount,
      date: dateStr,
      time: timeStr,
      dateTime: dateTimeStr,
      note: 'Ke ${r.to.name}',
      sign: '-',
    ));

    await widget.historyRepo.create(HistoryModel(
      categoryId: _kCategoryDestTransfer,
      accountId: r.to.id!,
      transferId: transferId,
      type: 2,
      amount: r.amount,
      date: dateStr,
      time: timeStr,
      dateTime: dateTimeStr,
      note: 'Dari ${r.from.name}',
      sign: '+',
    ));

    if (r.fee > 0) {
      await widget.historyRepo.create(HistoryModel(
        categoryId: _kCategoryTransferFee,
        accountId: r.from.id!,
        transferId: transferId,
        type: 4,
        amount: r.fee,
        date: dateStr,
        time: timeStr,
        dateTime: dateTimeStr,
        note: r.note.isEmpty ? 'Biaya transfer' : r.note,
        sign: '-',
      ));
    }
  }

  // ── Inline edit helpers (used in confirming phase) ────────────────

  Future<double?> _promptAmount({
    required String title,
    required double initial,
    bool allowZero = false,
  }) async {
    final controller = TextEditingController(
      text: initial > 0
          ? ThousandsInputFormatter.formatForDisplay(initial)
          : '',
    );
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsInputFormatter()],
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final raw = ThousandsInputFormatter.toRaw(controller.text);
              final v = double.tryParse(raw) ?? 0;
              if (!allowZero && v <= 0) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _editAmount() async {
    final r = _result;
    if (r == null) return;
    final current = switch (r) {
      _ParsedTx t => t.amount,
      _ParsedTransfer t => t.amount,
    };
    final newAmount = await _promptAmount(title: 'Ubah Nominal', initial: current);
    if (newAmount == null || newAmount <= 0 || !mounted) return;
    setState(() {
      _result = switch (r) {
        _ParsedTx t => t.copyWith(amount: newAmount),
        _ParsedTransfer t => t.copyWith(amount: newAmount),
      };
    });
  }

  Future<void> _editFee() async {
    final r = _result;
    if (r is! _ParsedTransfer) return;
    final newFee = await _promptAmount(
      title: 'Ubah Biaya Admin',
      initial: r.fee,
      allowZero: true,
    );
    if (newFee == null || !mounted) return;
    setState(() {
      _result = r.copyWith(fee: newFee);
    });
  }

  Future<void> _editCategory() async {
    final r = _result;
    if (r is! _ParsedTx) return;
    final filtered = _allCategories
        .where((c) => c.sign == r.sign && c.active == 1)
        .toList();
    final picked = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<CategoryModel>(
        title: 'Pilih Kategori',
        items: filtered,
        nameOf: (c) => c.name,
        iconOf: (c) => c.icon,
        colorOf: (c) => c.color,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _result = r.copyWith(category: picked));
    }
  }

  Future<void> _editAccount() async {
    final r = _result;
    if (r is! _ParsedTx) return;
    final filtered = _allAccounts.where((a) => a.active == 1).toList();
    final picked = await showModalBottomSheet<AccountModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<AccountModel>(
        title: 'Pilih Rekening',
        items: filtered,
        nameOf: (a) => a.name,
        iconOf: (a) => a.icon,
        colorOf: (a) => a.color,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _result = r.copyWith(account: picked));
    }
  }

  Future<void> _editFromAccount() async {
    final r = _result;
    if (r is! _ParsedTransfer) return;
    final filtered = _allAccounts
        .where((a) => a.active == 1 && a.id != r.to.id)
        .toList();
    if (filtered.isEmpty) return;
    final picked = await showModalBottomSheet<AccountModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<AccountModel>(
        title: 'Pilih Rekening Asal',
        items: filtered,
        nameOf: (a) => a.name,
        iconOf: (a) => a.icon,
        colorOf: (a) => a.color,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _result = r.copyWith(from: picked, fallbackUsed: false));
    }
  }

  Future<void> _editToAccount() async {
    final r = _result;
    if (r is! _ParsedTransfer) return;
    final filtered = _allAccounts
        .where((a) => a.active == 1 && a.id != r.from.id)
        .toList();
    if (filtered.isEmpty) return;
    final picked = await showModalBottomSheet<AccountModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<AccountModel>(
        title: 'Pilih Rekening Tujuan',
        items: filtered,
        nameOf: (a) => a.name,
        iconOf: (a) => a.icon,
        colorOf: (a) => a.color,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _result = r.copyWith(to: picked, fallbackUsed: false));
    }
  }

  Future<void> _editDateTime() async {
    final r = _result;
    if (r is! _ParsedTransfer) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: r.dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(r.dateTime),
    );
    if (pickedTime == null || !mounted) return;
    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() => _result = r.copyWith(dateTime: dt));
  }

  Future<void> _editNote() async {
    final r = _result;
    if (r == null) return;
    final currentNote = switch (r) {
      _ParsedTx t => t.note,
      _ParsedTransfer t => t.note,
    };
    final controller = TextEditingController(text: currentNote);
    final newNote = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Catatan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (newNote == null || !mounted) return;
    setState(() {
      _result = switch (r) {
        _ParsedTx t => t.copyWith(note: newNote),
        _ParsedTransfer t => t.copyWith(note: newNote),
      };
    });
  }

  Future<void> _toggleType() async {
    final r = _result;
    if (r is! _ParsedTx) return;
    final newSign = r.sign == '+' ? '-' : '+';
    final filtered = _allCategories
        .where((c) => c.sign == newSign && c.active == 1)
        .toList();
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada kategori ${newSign == '+' ? 'pemasukan' : 'pengeluaran'} aktif.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _result = r.copyWith(sign: newSign, category: filtered.first);
    });
  }

  /// Tukar rekening asal & tujuan (hanya untuk transfer).
  void _swapAccounts() {
    final r = _result;
    if (r is! _ParsedTransfer) return;
    setState(() {
      _result = r.copyWith(from: r.to, to: r.from, fallbackUsed: false);
    });
  }

  // ── Edit in full form (pre-filled with AI data) ───────────────────

  void _editInForm() {
    final r = _result;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    switch (r) {
      case null:
        router.push('/history/add');
      case _ParsedTx tx:
        router.push(
          '/history/add',
          extra: AddHistoryAiSeed(
            sign: tx.sign,
            amountText: tx.amount.toInt().toString(),
            note: tx.note,
            categoryName: tx.category.name,
            accountName: tx.account.name,
          ),
        );
      case _ParsedTransfer _:
        // Form transfer belum mendukung seed — buka kosong.
        router.push('/history/transfer/add');
    }
  }

  // ── Retry ───────────────────────────────────────────────────────────────────

  Future<void> _retry() async {
    await TtsService.instance.stop();
    setState(() {
      _phase = _Phase.listening;
      _transcript = '';
      _errorMsg = '';
      _result = null;
    });
    _startListening();
  }

  Future<void> _reprocess() async {
    await TtsService.instance.stop();
    setState(() {
      _errorMsg = '';
      _result = null;
    });
    _processTranscript();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom +
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _buildPhaseContent(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        );
      case _Phase.listening:
        return _buildListening();
      case _Phase.processing:
        return _buildProcessing();
      case _Phase.confirming:
        return _buildConfirming();
      case _Phase.saving:
        return _buildSaving();
      case _Phase.error:
        return _buildError();
    }
  }

  // ── Listening phase ─────────────────────────────────────────────────────────

  Widget _buildListening() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Transaksi Cepat AI',
          style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Ceritakan transaksimu',
          style: context.tt.bodySmall?.copyWith(
            color: context.cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Live transcript
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _transcript.isEmpty
                ? Text(
                    'Mendengarkan...',
                    key: const ValueKey('placeholder'),
                    style: context.tt.bodyMedium?.copyWith(
                      color: context.cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    _transcript,
                    key: const ValueKey('transcript'),
                    style: context.tt.bodyLarge,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),

        const SizedBox(height: 32),

        // Mic button with sound-level ring
        GestureDetector(
          onTap: _stopAndProcess,
          child: SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _idlePulseCtrl,
              builder: (_, __) {
                // Saat ada suara: pakai sound level. Saat diam: pakai idle pulse halus.
                final idle = 0.85 + (_idlePulseCtrl.value * 0.15);
                final responsive = 1.0 + (_soundLevel * 0.8);
                final scale = math.max(idle, responsive);
                final ringOpacity = 0.15 + (_soundLevel * 0.35);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.cs.primary
                              .withValues(alpha: ringOpacity),
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.cs.primary,
                        boxShadow: [
                          BoxShadow(
                            color: context.cs.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 36,
                        color: context.cs.onPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),
        Text(
          'Ketuk untuk selesai',
          style: context.tt.bodySmall?.copyWith(
            color: context.cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Processing phase ────────────────────────────────────────────────────────

  Widget _buildProcessing() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Sedang menganalisis...',
            style: context.tt.bodyMedium?.copyWith(
              color: context.cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI butuh waktu maksimal 30 detik',
            style: context.tt.bodySmall?.copyWith(
              color: context.cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  // ── Confirming phase ────────────────────────────────────────────────────────

  Widget _buildConfirming() {
    final r = _result!;
    return switch (r) {
      _ParsedTx tx => _buildConfirmingTx(tx),
      _ParsedTransfer tr => _buildConfirmingTransfer(tr),
    };
  }

  Widget _buildConfirmingTx(_ParsedTx r) {
    final isIncome = r.sign == '+';
    final typeColor = isIncome ? AppTheme.income : AppTheme.expense;
    final typeLabel = isIncome ? 'Pemasukan' : 'Pengeluaran';
    final typeIcon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: context.cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transaksi Terdeteksi',
                style: context.tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card
          Card(
            elevation: 0,
            color: context.cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + amount (tappable)
                  InkWell(
                    onTap: _editAmount,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleType,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(typeIcon,
                                      size: 14, color: typeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    typeLabel,
                                    style: context.tt.labelSmall?.copyWith(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(r.amount),
                            style: context.tt.titleLarge?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              size: 14,
                              color: context.cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  _ConfirmRow(
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: r.category.name,
                    onTap: _editCategory,
                  ),
                  _ConfirmRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Rekening',
                    value: r.account.name,
                    onTap: _editAccount,
                  ),
                  _ConfirmRow(
                    icon: Icons.notes_outlined,
                    label: 'Catatan',
                    value: r.note.isEmpty ? '— tap untuk tambah —' : r.note,
                    onTap: _editNote,
                  ),
                  _ConfirmRow(
                    icon: Icons.schedule_outlined,
                    label: 'Waktu',
                    value: 'Sekarang',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _editInForm,
                  child: const Text('Edit di Form'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmingTransfer(_ParsedTransfer r) {
    final accentColor = context.cs.primary;
    final dtLabel = _formatDateTimeLabel(r.dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transfer Terdeteksi',
                style: context.tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (r.fallbackUsed) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ AI menebak salah satu rekening — silakan periksa.',
                style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onErrorContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            color: context.cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount row (tappable)
                  InkWell(
                    onTap: _editAmount,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz,
                                    size: 14, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Transfer',
                                  style: context.tt.labelSmall?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(r.amount),
                            style: context.tt.titleLarge?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              size: 14,
                              color: context.cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  _ConfirmRow(
                    icon: Icons.north_east,
                    label: 'Dari',
                    value: r.from.name,
                    onTap: _editFromAccount,
                  ),
                  _ConfirmRow(
                    icon: Icons.south_west,
                    label: 'Ke',
                    value: r.to.name,
                    onTap: _editToAccount,
                    trailing: IconButton(
                      icon: const Icon(Icons.swap_vert, size: 18),
                      tooltip: 'Tukar Dari ↔ Ke',
                      onPressed: _swapAccounts,
                    ),
                  ),
                  _ConfirmRow(
                    icon: Icons.payments_outlined,
                    label: 'Biaya Admin',
                    value: r.fee > 0
                        ? CurrencyFormatter.format(r.fee)
                        : '— tap untuk tambah —',
                    onTap: _editFee,
                  ),
                  _ConfirmRow(
                    icon: Icons.schedule_outlined,
                    label: 'Waktu',
                    value: dtLabel,
                    onTap: _editDateTime,
                  ),
                  _ConfirmRow(
                    icon: Icons.notes_outlined,
                    label: 'Catatan',
                    value: r.note.isEmpty
                        ? '— tap untuk tambah —'
                        : r.note,
                    onTap: _editNote,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _editInForm,
                  child: const Text('Edit di Form'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTimeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    String day;
    if (diff == 0) {
      day = 'Hari ini';
    } else if (diff == 1) {
      day = 'Kemarin';
    } else if (diff == -1) {
      day = 'Besok';
    } else {
      String two(int n) => n.toString().padLeft(2, '0');
      day = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '$day ${two(dt.hour)}:${two(dt.minute)}';
  }

  // ── Saving phase ────────────────────────────────────────────────────────────

  Widget _buildSaving() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Menyimpan...'),
        ],
      ),
    );
  }

  // ── Error phase ─────────────────────────────────────────────────────────────

  Widget _buildError() {
    final hasTranscript = _transcript.trim().isNotEmpty;
    if (_permissionDenied) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_off_outlined,
                size: 48, color: context.cs.error),
            const SizedBox(height: 12),
            Text(
              'Izin Mikrofon Ditolak',
              style: context.tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Buka Pengaturan \u203A Aplikasi \u203A Dompetku \u203A Izin, '
              'lalu aktifkan Mikrofon. Setelah itu coba lagi.',
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.cs.error),
          const SizedBox(height: 12),
          Text(
            _errorMsg,
            style: context.tt.bodyMedium?.copyWith(color: context.cs.error),
            textAlign: TextAlign.center,
          ),
          if (hasTranscript) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil dengar:',
                    style: context.tt.labelSmall?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_transcript, style: context.tt.bodyMedium),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.mic, size: 18),
                  label: const Text('Rekam Ulang'),
                ),
              ),
              if (hasTranscript) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _reprocess,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Proses Ulang'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable confirm row ─────────────────────────────────────────────────────

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: context.cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: context.tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null)
              Icon(Icons.edit_outlined,
                  size: 14, color: context.cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Generic picker bottom sheet (reusable for category/account) ───────────

class _PickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) nameOf;
  final String Function(T) iconOf;
  final String Function(T) colorOf;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.nameOf,
    required this.iconOf,
    required this.colorOf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: context.tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final bg = ColoredIcon.parseColor(colorOf(item));
              return ListTile(
                leading: ColoredIcon(
                  iconName: iconOf(item),
                  backgroundColor: bg,
                  size: 40,
                  iconSize: 22,
                ),
                title: Text(nameOf(item)),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
