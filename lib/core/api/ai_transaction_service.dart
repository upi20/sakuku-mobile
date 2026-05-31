import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../utils/ai_key_service.dart';

/// Hasil parsing AI — union dua bentuk:
/// - [AiParsedTransaction] untuk pemasukan/pengeluaran biasa.
/// - [AiParsedTransfer] untuk transfer antar rekening.
sealed class AiParseResult {
  const AiParseResult();
}

class AiParsedTransaction extends AiParseResult {
  /// '+' untuk pemasukan, '-' untuk pengeluaran.
  final String sign;

  /// Raw digit string, e.g. "50000".
  final String amountText;

  final String note;
  final String categoryName;
  final String accountName;

  const AiParsedTransaction({
    required this.sign,
    required this.amountText,
    required this.note,
    required this.categoryName,
    required this.accountName,
  });
}

class AiParsedTransfer extends AiParseResult {
  /// Raw digit string nominal transfer.
  final String amountText;

  /// Raw digit string biaya admin. Kosong = tanpa biaya.
  final String feeText;

  final String note;
  final String fromAccountName;
  final String toAccountName;

  /// Null = pakai waktu sekarang.
  final DateTime? datetime;

  const AiParsedTransfer({
    required this.amountText,
    required this.feeText,
    required this.note,
    required this.fromAccountName,
    required this.toAccountName,
    this.datetime,
  });
}

class AiTransactionService {
  AiTransactionService._();
  static final AiTransactionService instance = AiTransactionService._();

  /// Mengubah teks kasual menjadi [AiParseResult].
  ///
  /// [allowTransfer] — jika false, AI dipaksa selalu menghasilkan
  /// [AiParsedTransaction] (untuk form add-history yang single-account).
  Future<AiParseResult> parse({
    required String userInput,
    required List<CategoryModel> categories,
    required List<AccountModel> accounts,
    bool allowTransfer = true,
  }) async {
    final apiKey = await AiKeyService.instance.getKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
          'API Key Gemini belum diset.\nBuka Pengaturan → AI untuk menambahkannya.');
    }

    final expenseCategories = categories
        .where((c) => c.isExpense && c.active == 1)
        .map((c) => c.name)
        .toList();
    final incomeCategories = categories
        .where((c) => c.isIncome && c.active == 1)
        .map((c) => c.name)
        .toList();
    final accountNames = accounts
        .where((a) => a.active == 1)
        .map((a) => a.name)
        .toList();

    final now = DateTime.now();
    final nowIso = _formatLocalIso(now);

    final transferBlock = allowTransfer
        ? '''

JENIS OUTPUT — ada DUA bentuk, ditentukan field "type":
- "type": "transaction"  → pemasukan / pengeluaran biasa.
- "type": "transfer"     → pindah dana antar rekening sendiri.
  Kata kunci: "transfer", "pindah", "kirim ke", "topup ke", "tarik tunai", "setor".

JIKA "type" = "transfer", OUTPUT WAJIB:
{
  "type": "transfer",
  "amount": int,
  "fee": int,                 // biaya admin, 0 jika tidak ada
  "from_account": "string",   // wajib dari daftar Rekening
  "to_account": "string",     // wajib dari daftar Rekening, berbeda dari from_account
  "datetime": "YYYY-MM-DDTHH:MM:SS" | null,
  "note": "string"
}
'''
        : '\n\nSEMUA input WAJIB diproses sebagai "type": "transaction". '
            'Abaikan kata transfer/pindah — perlakukan sebagai pengeluaran biasa.';

    final systemInstruction = '''
Kamu adalah mesin pengolah teks transaksi keuangan. Ubah teks kasual menjadi JSON terstruktur.

WAKTU SAAT INI (local): $nowIso

DATA VALID SAAT INI:
- Kategori Pengeluaran (sign "-"): $expenseCategories
- Kategori Pemasukan (sign "+"): $incomeCategories
- Rekening: $accountNames
$transferBlock

JIKA "type" = "transaction", OUTPUT WAJIB:
{
  "type": "transaction",
  "sign": "+" | "-",
  "amount": int,
  "note": "string",
  "category": "string",   // wajib cocok dari daftar Kategori sesuai sign
  "account": "string"     // wajib cocok dari daftar Rekening
}

ATURAN UMUM:
1. Cocokkan ke Kategori dan Rekening yang paling mirip dari daftar di atas.
2. Jika rekening tidak disebutkan, gunakan rekening pertama dari daftar.
3. "amount" dan "fee" integer murni tanpa titik/koma: "50rb"=50000, "1.5jt"=1500000, "2k"=2000.
4. "note" ringkasan singkat dalam bahasa Indonesia, maksimal 60 karakter.
5. "datetime" format ISO 8601 local time tanpa timezone. Resolusi relatif:
   - "kemarin" = tanggal sekarang dikurangi 1 hari (jam dipertahankan jika disebut, default 12:00:00).
   - "tadi pagi/siang/sore/malam" = hari ini (08:00 / 13:00 / 16:00 / 20:00).
   - Tidak disebut waktu = null (pakai waktu sekarang).

OUTPUT WAJIB hanya JSON, tidak ada teks lain.
''';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(systemInstruction),
    );

    debugPrint('┌─ [AI] REQUEST ─────────────────────────────────');
    debugPrint('│ user input    : "$userInput"');
    debugPrint('│ allowTransfer : $allowTransfer');
    debugPrint('│ expense       : $expenseCategories');
    debugPrint('│ income        : $incomeCategories');
    debugPrint('│ accounts      : $accountNames');
    debugPrint('│ now           : $nowIso');
    debugPrint('└────────────────────────────────────────────────');

    final response = await model
        .generateContent([Content.text(userInput)])
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
            'AI tidak merespons (timeout 30s). Periksa koneksi internet dan coba lagi.',
          ),
        );
    final text = response.text;

    debugPrint('┌─ [AI] RESPONSE ────────────────────────────────');
    debugPrint('│ raw : $text');
    debugPrint('└────────────────────────────────────────────────');

    if (text == null || text.isEmpty) {
      throw Exception('Respons AI kosong. Coba ulangi.');
    }

    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[AI] JSON parse error: $e');
      throw Exception('Respons AI tidak valid (bukan JSON). Coba ulangi.');
    }

    debugPrint('[AI] parsed: $json');

    final type = (json['type'] ?? 'transaction').toString().toLowerCase();
    if (type == 'transfer' && allowTransfer) {
      return _parseTransfer(json);
    }
    return _parseTransaction(json);
  }

  AiParsedTransaction _parseTransaction(Map<String, dynamic> json) {
    final rawSign = (json['sign'] ?? '').toString().trim().toLowerCase();
    final String sign;
    if (rawSign == '+' ||
        rawSign == 'pemasukan' ||
        rawSign == 'income' ||
        rawSign == 'in') {
      sign = '+';
    } else if (rawSign == '-' ||
        rawSign == 'pengeluaran' ||
        rawSign == 'expense' ||
        rawSign == 'out') {
      sign = '-';
    } else {
      throw Exception('Respons AI tidak valid: sign "$rawSign" tidak dikenali.');
    }

    final amountRaw = json['amount'];
    if (amountRaw is! num) {
      throw Exception('Respons AI tidak valid: amount bukan angka.');
    }

    return AiParsedTransaction(
      sign: sign,
      amountText: '${amountRaw.toInt()}',
      note: (json['note'] ?? '').toString(),
      categoryName: (json['category'] ?? '').toString(),
      accountName: (json['account'] ?? '').toString(),
    );
  }

  AiParsedTransfer _parseTransfer(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    if (amountRaw is! num) {
      throw Exception('Respons AI tidak valid: amount transfer bukan angka.');
    }
    final feeRaw = json['fee'];
    final fee = feeRaw is num ? feeRaw.toInt() : 0;

    final from = (json['from_account'] ?? '').toString().trim();
    final to = (json['to_account'] ?? '').toString().trim();
    if (from.isEmpty || to.isEmpty) {
      throw Exception(
          'Respons AI tidak valid: from_account / to_account kosong.');
    }

    DateTime? dt;
    final dtRaw = json['datetime'];
    if (dtRaw is String && dtRaw.isNotEmpty && dtRaw.toLowerCase() != 'null') {
      try {
        dt = DateTime.parse(dtRaw);
      } catch (_) {
        dt = null;
      }
    }

    return AiParsedTransfer(
      amountText: '${amountRaw.toInt()}',
      feeText: fee > 0 ? '$fee' : '',
      note: (json['note'] ?? '').toString(),
      fromAccountName: from,
      toAccountName: to,
      datetime: dt,
    );
  }

  static String _formatLocalIso(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}'
        'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}
