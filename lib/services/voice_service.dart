import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Supported locales for recognition - tries each if one fails
const kSupportedLocales = [
  'fr-FR', // French (primary for Tunisia)
  'fr-TN', // French Tunisia
  'ar-TN', // Arabic Tunisia
  'ar-SA', // Arabic
  'en-US', // English fallback
];

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  String? _activeLocaleId;
  List<LocaleName> _availableLocales = [];

  bool get isListening => _speech.isListening;
  bool get isAvailable => _initialized;
  List<LocaleName> get availableLocales => _availableLocales;
  String? get activeLocale => _activeLocaleId;

  /// Initialize speech recognition and find available locales
  Future<bool> initialize() async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onError: _onError,
      debugLogging: false,
    );

    if (_initialized) {
      _availableLocales = await _speech.locales();
      _activeLocaleId = _pickBestLocale();
    }

    return _initialized;
  }

  /// Pick the best locale from the supported list
  String? _pickBestLocale() {
    for (final preferred in kSupportedLocales) {
      for (final available in _availableLocales) {
        if (available.localeId.startsWith(preferred.split('-')[0])) {
          return available.localeId;
        }
      }
    }
    // Fallback to system default
    return _availableLocales.isNotEmpty ? _availableLocales.first.localeId : null;
  }

  /// Start listening. Calls [onResult] with interim + final results.
  /// Calls [onDone] when listening ends.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
    String? localeId,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_speech.isListening) await stopListening();

    final locale = localeId ?? _activeLocaleId;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),  // long session
      pauseFor: const Duration(seconds: 4),    // pause tolerance
      localeId: locale,
      cancelOnError: false,
      partialResults: true,                    // stream interim words
      listenMode: ListenMode.dictation,        // best for long phrases
      onSoundLevelChange: null,
    );

    // Notify when speech engine stops on its own
    Future.delayed(const Duration(milliseconds: 200), () {
      _speech.statusListener = (status) {
        if (status == 'done' || status == 'notListening') {
          onDone();
        }
      };
    });
  }

  /// Stop recognition manually
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancel without result
  Future<void> cancel() async {
    await _speech.cancel();
  }

  void _onError(SpeechRecognitionError error) {
    // Errors are surfaced to UI via status, not thrown
  }

  void setLocale(String localeId) {
    _activeLocaleId = localeId;
  }

  void dispose() {
    _speech.cancel();
  }
}