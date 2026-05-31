import 'package:speech_to_text/speech_to_text.dart';

/// Dilempar saat izin mikrofon ditolak oleh pengguna.
class MicPermissionDeniedException implements Exception {
  final String message;
  MicPermissionDeniedException([this.message = 'Izin mikrofon ditolak.']);
  @override
  String toString() => message;
}

/// Singleton STT untuk input suara transaksi.
class VoiceInputService {
  VoiceInputService._();
  static final VoiceInputService instance = VoiceInputService._();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _ignoreResults = false;
  String? _lastError;

  Future<bool> _init() async {
    if (_initialized) return true;
    _lastError = null;
    _initialized = await _speech.initialize(
      onError: (e) => _lastError = e.errorMsg,
    );
    return _initialized;
  }

  bool get isListening => _speech.isListening;

  /// Throws [MicPermissionDeniedException] kalau izin ditolak,
  /// atau [Exception] umum kalau perangkat tidak mendukung.
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!await _init()) {
      final err = _lastError?.toLowerCase() ?? '';
      if (err.contains('permission') || err.contains('denied')) {
        throw MicPermissionDeniedException(
          'Izin mikrofon ditolak. Buka Pengaturan → Aplikasi → DompetKu → Izin → Mikrofon.',
        );
      }
      throw Exception('Speech recognition tidak tersedia di perangkat ini.');
    }
    _ignoreResults = false;
    bool sessionDone = false;
    await _speech.listen(
      onResult: (result) {
        if (_ignoreResults || sessionDone) return;
        onResult(result.recognizedWords);
        if (result.finalResult) {
          sessionDone = true;
          onDone();
        }
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        localeId: 'id-ID',
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 120),
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() {
    _ignoreResults = true;
    return _speech.stop();
  }

  Future<void> cancel() {
    _ignoreResults = true;
    return _speech.cancel();
  }
}
