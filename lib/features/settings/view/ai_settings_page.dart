import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ai_key_service.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final _controller = TextEditingController();
  bool _hasKey = false;
  bool _loading = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final has = await AiKeyService.instance.hasKey();
    if (mounted) setState(() {
      _hasKey = has;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    await AiKeyService.instance.setKey(key);
    _controller.clear();
    if (mounted) {
      setState(() => _hasKey = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key berhasil disimpan')),
      );
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus API Key?'),
        content: const Text(
          'Fitur AI tidak akan bisa digunakan hingga API key baru ditambahkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Hapus',
              style: TextStyle(color: context.cs.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AiKeyService.instance.removeKey();
    if (mounted) setState(() => _hasKey = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Header card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: cs.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gemini AI',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Model: gemini-2.5-flash-lite',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Status & form ─────────────────────────────────────────
                if (_hasKey) ...[
                  // Status: key terpasang
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'API Key terpasang',
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Fitur AI siap digunakan',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _remove,
                          style: TextButton.styleFrom(
                              foregroundColor: cs.error),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Form input API key
                  Text(
                    'Masukkan API Key',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'AIza...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                        tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Simpan API Key'),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Info card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi',
                            style: tt.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Cara dapat API Key',
                        value: 'aistudio.google.com/apikey',
                        cs: cs,
                        tt: tt,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Penyimpanan',
                        value: 'Lokal di perangkat, tidak dikirim ke server lain',
                        cs: cs,
                        tt: tt,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Biaya',
                        value: 'Gratis hingga kuota tertentu per bulan',
                        cs: cs,
                        tt: tt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: tt.bodySmall?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}
