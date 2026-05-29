import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../services/geocoding/geocoding_service.dart';
import 'voice_modules/voice_constants.dart';
import 'voice_modules/voice_logger.dart';
import 'voice_modules/voice_api_service.dart';
import 'voice_modules/voice_widgets.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final void Function(Map<String, String?> booking)? onBookingConfirmed;
  final void Function(String query)? onSearchQuery;

  const VoiceAssistantScreen({
    super.key,
    this.onBookingConfirmed,
    this.onSearchQuery,
  });

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  // ── State ─────────────────────────────────────────────────
  VoicePhase _phase = VoicePhase.idle;
  String _statusMsg = 'Tap to speak';
  String _transcript = '';
  String _language = 'fr'; // toujours initialisé à 'fr'

  // ── Booking context ───────────────────────────────────────
  String? _destination;
  String? _departure;
  String? _date;
  String? _time;
  List<String> _missingFields = [];
  String? _currentField; // champ attendu pour la prochaine réponse
  String? _confirmationText;
  String? _searchQuery;

  // ── Timer / recording ─────────────────────────────────────
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _audioPath;
  static const int kMaxSeconds = 60;

  // ── Animations ────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _ring1Anim;
  late Animation<double> _ring2Anim;
  late Animation<double> _ring3Anim;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    voiceLog('INIT', 'VoiceAssistantScreen mounted — backend: $kBackendUrl');
    _initAnimations();
    _initTts();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _ring1Anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ring2Anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
      ),
    );
    _ring3Anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recorder.dispose();
    _tts.stop();
    _timer?.cancel();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // TTS
  // ─────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (_phase == VoicePhase.question) {
        voiceLog('TTS', 'Speech finished → starting answer recording');
        _startAnswerRecording();
      } else {
        voiceLog('TTS', 'Speech finished (phase=$_phase, no action)');
      }
    });
  }

  Future<void> _speak(String text, String lang) async {
    final locale = switch (lang) {
      'ar' => 'ar-SA',
      'en' => 'en-US',
      _ => 'fr-FR',
    };
    voiceLog('TTS', 'speak  lang=$locale  →  "$text"');
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  // ─────────────────────────────────────────────────────────
  // Permissions & paths
  // ─────────────────────────────────────────────────────────
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    _setError('Microphone permission denied.');
    return false;
  }

  Future<String> _newAudioPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/mv_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  // ─────────────────────────────────────────────────────────
  // Recording
  // ─────────────────────────────────────────────────────────
  Future<void> _startRecording({bool isAnswer = false}) async {
    if (!await _checkPermission()) return;

    _audioPath = await _newAudioPath();
    voiceLog(
      'REC',
      '${isAnswer ? 'ANSWER' : 'INITIAL'} recording started → $_audioPath',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _audioPath!,
    );

    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed.inSeconds >= kMaxSeconds) {
        voiceLog('REC', 'Max duration (${kMaxSeconds}s) — auto stop');
        isAnswer ? _stopAndAnswer() : _stopAndTranscribe();
      }
    });

    setState(() {
      _phase = isAnswer ? VoicePhase.waitAnswer : VoicePhase.recording;
      _statusMsg = isAnswer ? 'LISTENING...' : 'SAYING...';
      // Reset contexte SEULEMENT pour un nouvel enregistrement initial
      if (!isAnswer) {
        _transcript = '';
        _destination = null;
        _departure = null;
        _date = null;
        _time = null;
        _missingFields = [];
        _confirmationText = null;
        _searchQuery = null;
        _currentField = null; // reset aussi currentField
      }
    });
  }

  Future<void> _startAnswerRecording() => _startRecording(isAnswer: true);

  Future<void> _stopAndTranscribe() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) {
      _setError('Recording failed.');
      return;
    }

    _audioPath = path;
    voiceLog('REC', 'Initial recording stopped → $path');
    setState(() {
      _phase = VoicePhase.uploading;
      _statusMsg = 'PROCESSING...';
    });

    try {
      final result = await VoiceApiService.transcribe(_audioPath!);
      await _handleResult(result);
    } catch (e) {
      voiceLog('ERROR', e);
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _stopAndAnswer() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) {
      _setError('Answer not recorded.');
      return;
    }
    _audioPath = path;

    // CAPTURER avant setState — c'est le bug principal
    final String field = (_currentField != null && _currentField!.isNotEmpty)
        ? _currentField!
        : 'destination';
    final String lang = _language.isNotEmpty ? _language : 'fr';
    final String? dest = _destination;
    final String? dep = _departure;
    final String? date = _date;
    final String? time = _time;

    // CE LOG doit apparaître dans Flutter avant l'appel API
    voiceLog(
      'STOP_ANSWER',
      'field="$field" lang="$lang"\n'
          '║  dest=$dest dep=$dep date=$date time=$time',
    );

    setState(() {
      _phase = VoicePhase.uploading;
      _statusMsg = 'PROCESSING...';
    });

    try {
      final result = await VoiceApiService.answer(
        _audioPath!,
        field: field,
        language: lang,
        destination: dest,
        departure: dep,
        date: date,
        time: time,
      );
      await _handleResult(result);
    } catch (e) {
      voiceLog('ERROR', e);
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ─────────────────────────────────────────────────────────
  // Handle result
  // ─────────────────────────────────────────────────────────
  Future<void> _handleResult(Map<String, dynamic> result) async {
    voiceLogJson('RESULT RAW', result);

    _transcript = result['text'] as String? ?? '';

    // ── FIX : ne pas écraser _language si le serveur renvoie 'un' ou vide ──
    final serverLang = result['language'] as String? ?? '';
    if (serverLang.length >= 2 && serverLang != 'un') {
      _language = serverLang.substring(0, 2);
    }

    final intent = result['intent'] as String? ?? 'search';

    voiceLog(
      'RESULT',
      'text     = "$_transcript"\n'
          '║  language = $_language\n'
          '║  intent   = $intent',
    );

    // ── SEARCH ─────────────────────────────────────────────
    if (intent == 'search') {
      final query = result['search_query'] as String? ?? _transcript;
      voiceLog('SEARCH', 'query = "$query"');
      setState(() {
        _searchQuery = query;
        _phase = VoicePhase.search;
        _statusMsg = 'RESULT';
      });
      widget.onSearchQuery?.call(query);
      await _speak(query, _language);
      return;
    }

    // ── BOOKING ────────────────────────────────────────────
    // FIX : merge — on garde la valeur existante si le serveur renvoie null
    _destination = (result['destination'] as String?)?.isNotEmpty == true
        ? result['destination'] as String
        : _destination;

    _departure = (result['departure'] as String?)?.isNotEmpty == true
        ? result['departure'] as String
        : _departure;

    _date = (result['date'] as String?)?.isNotEmpty == true
        ? result['date'] as String
        : _date;

    _time = (result['time'] as String?)?.isNotEmpty == true
        ? result['time'] as String
        : _time;

    _missingFields = List<String>.from(result['missing_fields'] ?? []);
    _confirmationText = result['confirmation'] as String?;

    voiceLog(
      'BOOKING ENTITIES',
      'destination    = $_destination\n'
          '║  departure      = $_departure\n'
          '║  date           = $_date\n'
          '║  time           = $_time\n'
          '║  missing_fields = $_missingFields\n'
          '║  confirmation   = $_confirmationText',
    );

    final nextQ = result['next_question'] as Map<String, dynamic>?;

    // ── Tous les champs OK → confirmation ──────────────────
    if (_missingFields.isEmpty && _confirmationText != null) {
      final booking = {
        'destination': _destination,
        'departure': _departure,
        'date': _date,
        'time': _time,
      };
      voiceLogJson(
        'BOOKING CONFIRMED ✅',
        booking.map((k, v) => MapEntry(k, v ?? 'null')),
      );
      setState(() {
        _phase = VoicePhase.result;
        _statusMsg = 'CONFIRMED';
      });
      widget.onBookingConfirmed?.call(booking);
      await _speak(_confirmationText!, _language);
      return;
    }

    // ── Champs manquants → question suivante ───────────────
    if (nextQ != null) {
      // FIX : stocker _currentField AVANT setState + await _speak
      _currentField = nextQ['field'] as String?;
      final question = nextQ['question'] as String? ?? '';

      voiceLog(
        'NEXT QUESTION',
        'field    = $_currentField\n'
            '║  question = "$question"',
      );

      // setState phase=question EN PREMIER
      setState(() {
        _phase = VoicePhase.question;
        _statusMsg = question;
      });

      // _speak lance le TTS → à la fin, TTS completion handler
      // appelle _startAnswerRecording() car _phase == question
      await _speak(question, _language);
    } else {
      voiceLog(
        'WARN',
        'missing_fields=$_missingFields but next_question=null — check backend',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  void _setError(String msg) {
    voiceLog('ERROR', msg);
    setState(() {
      _phase = VoicePhase.error;
      _statusMsg = msg;
    });
  }

  void _reset() {
    voiceLog('RESET', 'back to idle');
    _tts.stop();
    _timer?.cancel();
    setState(() {
      _phase = VoicePhase.idle;
      _statusMsg = 'Tap to speak';
      _transcript = '';
      _language = 'fr';
      _destination = null;
      _departure = null;
      _date = null;
      _time = null;
      _missingFields = [];
      _confirmationText = null;
      _searchQuery = null;
      _currentField = null;
      _elapsed = Duration.zero;
    });
  }

  // ─────────────────────────────────────────────────────────
  // Confirm → geocode → navigate to search with pre-filled data
  // ─────────────────────────────────────────────────────────
  bool _isConfirming = false;

  Future<void> _onConfirmBooking() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      final geocoding = GeocodingService();

      // Geocode pickup (departure)
      final pickupQuery =
          (_departure != null &&
              _departure!.isNotEmpty &&
              _departure != 'current_location')
          ? _departure!
          : null;

      GeocodingPlace? pickupPlace;
      if (pickupQuery != null) {
        final locale = Localizations.localeOf(context).languageCode;
        final results = await geocoding.searchPlaces(
          pickupQuery,
          language: locale,
        );
        if (results.isNotEmpty) pickupPlace = results.first;
      }

      // Geocode dropoff (destination)
      GeocodingPlace? dropoffPlace;
      if (_destination != null && _destination!.isNotEmpty) {
        final locale = Localizations.localeOf(context).languageCode;
        final results = await geocoding.searchPlaces(
          _destination!,
          language: locale,
        );
        if (results.isNotEmpty) dropoffPlace = results.first;
      }

      if (!mounted) return;

      if (dropoffPlace == null || !dropoffPlace.hasValidCoordinates) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find destination. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Parse date/time from voice result
      DateTime? pickedDate;
      TimeOfDay? pickedTime;
      if (_date != null && _date!.isNotEmpty) {
        try {
          pickedDate = DateTime.parse(_date!);
        } catch (_) {}
      }
      if (_time != null && _time!.isNotEmpty) {
        try {
          final parts = _time!.split(':');
          if (parts.length >= 2) {
            pickedTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (_) {}
      }

      // Navigate to LocationScreen with pre-filled voice results
      final isCurrentLoc =
          _departure == null ||
          _departure!.isEmpty ||
          _departure == 'current_location';

      Navigator.pushReplacementNamed(
        context,
        '/nextdestinationsearch',
        arguments: {
          'pickupPlace': pickupPlace,
          'dropoffPlace': dropoffPlace,
          'pickupAddress': isCurrentLoc
              ? 'current_location'
              : (pickupPlace?.localizedPlaceName() ?? _departure ?? ''),
          'dropoffAddress': dropoffPlace.localizedPlaceName(),
          'pickupLat': pickupPlace?.latitude,
          'pickupLon': pickupPlace?.longitude,
          'dropoffLat': dropoffPlace.latitude,
          'dropoffLon': dropoffPlace.longitude,
          'date': pickedDate ?? DateTime.now(),
          'time': pickedTime,
          'useCurrentLocation': isCurrentLoc,
        },
      );
    } catch (e) {
      voiceLog('CONFIRM_ERROR', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _onMicTap() {
    voiceLog('TAP', 'phase=$_phase');
    switch (_phase) {
      case VoicePhase.uploading:
      case VoicePhase.question:
        return;
      case VoicePhase.recording:
        _stopAndTranscribe();
      case VoicePhase.waitAnswer:
        _stopAndAnswer();
      default:
        _startRecording();
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: voiceBg(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            buildTopBar(
              context,
              onBackPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    buildCenter(
                      context,
                      phase: _phase,
                      pulseAnim: _pulseAnim,
                      ring1Anim: _ring1Anim,
                      ring2Anim: _ring2Anim,
                      ring3Anim: _ring3Anim,
                      waveCtrl: _waveCtrl,
                      onMicTap: _onMicTap,
                      elapsed: _elapsed,
                      statusMsg: _statusMsg,
                      transcript: _transcript,
                      confirmationText: _confirmationText,
                      searchQuery: _searchQuery,
                    ),
                    buildBottomArea(
                      context,
                      phase: _phase,
                      onReset: _reset,
                      onConfirm: _phase == VoicePhase.result && !_isConfirming
                          ? _onConfirmBooking
                          : null,
                      departure: _departure,
                      destination: _destination,
                      date: _date,
                      time: _time,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
