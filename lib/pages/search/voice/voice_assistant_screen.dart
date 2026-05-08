import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'voice_modules/voice_constants.dart';
import 'voice_modules/voice_logger.dart';
import 'voice_modules/voice_api_service.dart';
import 'voice_modules/voice_widgets.dart';

// ─────────────────────────────────────────────────────────────
// VoiceAssistantScreen
// ─────────────────────────────────────────────────────────────
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
  String _language = 'fr';

  // ── Booking ───────────────────────────────────────────────
  String? _destination;
  String? _departure;
  String? _date;
  String? _time;
  List<String> _missingFields = [];
  String? _currentField;
  String? _confirmationText;
  String? _searchQuery;

  // ── Timer ─────────────────────────────────────────────────
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

    _initTts();
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
      voiceLog('TTS', 'Speech finished → starting answer recording');
      if (_phase == VoicePhase.question) _startAnswerRecording();
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
        voiceLog('REC', 'Max duration reached (${kMaxSeconds}s) — auto stop');
        if (isAnswer)
          _stopAndAnswer();
        else
          _stopAndTranscribe();
      }
    });

    setState(() {
      _phase = isAnswer ? VoicePhase.waitAnswer : VoicePhase.recording;
      _statusMsg = isAnswer ? 'ANSWERING...' : 'SAYING...';
      if (!isAnswer) {
        _transcript = '';
        _destination = null;
        _departure = null;
        _date = null;
        _time = null;
        _missingFields = [];
        _confirmationText = null;
        _searchQuery = null;
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
    voiceLog('REC', 'Answer recording stopped → $path  field=$_currentField');
    setState(() {
      _phase = VoicePhase.uploading;
      _statusMsg = 'PROCESSING...';
    });
    try {
      final result = await VoiceApiService.answer(
        _audioPath!,
        field: _currentField ?? 'destination',
        language: _language,
        destination: _destination,
        departure: _departure,
        date: _date,
        time: _time,
      );
      await _handleResult(result);
    } catch (e) {
      voiceLog('ERROR', e);
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ─────────────────────────────────────────────────────────
  // Handle result  ← MAIN DEBUG POINT
  // ─────────────────────────────────────────────────────────
  Future<void> _handleResult(Map<String, dynamic> result) async {
    // ── Print raw server response ──────────────────────────
    voiceLogJson('RESULT RAW', result);

    _transcript = result['text'] as String? ?? '';
    _language = (result['language'] as String? ?? 'fr').substring(0, 2);
    final intent = result['intent'] as String? ?? 'search';

    voiceLog(
      'RESULT',
      'text     = "$_transcript"\n'
          '║  language = $_language\n'
          '║  intent   = $intent',
    );

    // ── SEARCH intent ──────────────────────────────────────
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

    // ── BOOKING intent ─────────────────────────────────────
    _destination = result['destination'] as String?;
    _departure = result['departure'] as String?;
    _date = result['date'] as String?;
    _time = result['time'] as String?;
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

    // ── All fields complete → confirmed ────────────────────
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

    // ── Missing fields → ask next question ─────────────────
    if (nextQ != null) {
      _currentField = nextQ['field'] as String?;
      final question = nextQ['question'] as String? ?? '';

      voiceLog(
        'NEXT QUESTION',
        'field    = $_currentField\n'
            '║  question = "$question"',
      );

      setState(() {
        _phase = VoicePhase.question;
        _statusMsg = question;
      });
      await _speak(question, _language);
    } else {
      voiceLog(
        'WARN',
        'missing_fields=$_missingFields but next_question is null — check backend',
      );
    }
  }

  void _setError(String msg) {
    voiceLog('ERROR', msg);
    setState(() {
      _phase = VoicePhase.error;
      _statusMsg = msg;
    });
  }

  void _reset() {
    voiceLog('RESET', 'User reset — back to idle');
    setState(() {
      _phase = VoicePhase.idle;
      _statusMsg = 'Tap to speak';
      _transcript = '';
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

  void _onMicTap() {
    voiceLog('TAP', 'phase=$_phase');
    if (_phase == VoicePhase.uploading || _phase == VoicePhase.question) return;
    if (_phase == VoicePhase.recording) {
      _stopAndTranscribe();
      return;
    }
    if (_phase == VoicePhase.waitAnswer) {
      _stopAndAnswer();
      return;
    }
    _startRecording();
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height after top bar and safe area
            final topBarHeight = 80.0;
            final bottomAreaHeight = _phase == VoicePhase.result
                ? 180.0
                : 120.0;
            final availableHeight =
                constraints.maxHeight - topBarHeight - bottomAreaHeight;

            return Column(
              children: [
                buildTopBar(onBackPressed: () => Navigator.maybePop(context)),
                Flexible(
                  child: SizedBox(
                    height: availableHeight,
                    child: buildCenter(
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
                  ),
                ),
                buildBottomArea(
                  phase: _phase,
                  onReset: _reset,
                  departure: _departure,
                  destination: _destination,
                  date: _date,
                  time: _time,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
