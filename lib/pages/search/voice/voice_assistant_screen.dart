import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../services/geocoding/geocoding_service.dart';
import '../../../services/gps/gps_service.dart';
import '../../../l10n/app_localizations.dart';
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
  String _statusMsg = ''; // set in didChangeDependencies
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

  // ── Loading / confirm ─────────────────────────────────────
  bool _isLoading = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statusMsg.isEmpty) {
      _statusMsg = AppLocalizations.of(context).translate('voice_tap_to_speak');
    }
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
    String locale;

    if (lang == 'ar') {
      // Try different Arabic locales in order of preference
      final arabicLocales = ['ar-SA', 'ar-EG', 'ar-MA', 'ar-TN', 'ar'];
      locale = arabicLocales.first;

      // Try each locale until one works
      for (final arabicLocale in arabicLocales) {
        try {
          await _tts.setLanguage(arabicLocale);
          locale = arabicLocale;
          voiceLog('TTS', 'speak lang=$locale → "$text"');
          await _tts.speak(text);
          return;
        } catch (e) {
          voiceLog('TTS', 'Failed to set language $arabicLocale: $e');
          continue;
        }
      }

      // If all Arabic locales failed, fallback to English
      voiceLog('TTS', 'No Arabic locale worked, falling back to English');
      locale = 'en-US';
    } else {
      locale = switch (lang) {
        'en' => 'en-US',
        _ => 'fr-FR',
      };
    }

    voiceLog('TTS', 'speak lang=$locale → "$text"');
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  // ─────────────────────────────────────────────────────────
  // Permissions & paths
  // ─────────────────────────────────────────────────────────
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    _setError(AppLocalizations.of(context).translate('voice_mic_permission_denied'));
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
      _statusMsg = AppLocalizations.of(context).translate(isAnswer ? 'voice_listening' : 'voice_saying');
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
      _setError(AppLocalizations.of(context).translate('voice_recording_failed'));
      return;
    }

    _audioPath = path;
    voiceLog('REC', 'Initial recording stopped → $path');
    setState(() {
      _phase = VoicePhase.uploading;
      _statusMsg = AppLocalizations.of(context).translate('voice_processing');
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
      _setError(AppLocalizations.of(context).translate('voice_answer_not_recorded'));
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
      _statusMsg = AppLocalizations.of(context).translate('voice_processing');
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
      _statusMsg = AppLocalizations.of(context).translate('voice_tap_to_speak');
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
  // Disambiguation: show bottom sheet when multiple results
  // ─────────────────────────────────────────────────────────
  Future<GeocodingPlace?> _showDisambiguationSheet(
    String query,
    List<GeocodingPlace> results,
  ) async {
    if (results.isEmpty) return null;
    if (results.length == 1) return results.first;

    return await showModalBottomSheet<GeocodingPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: voiceBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: voiceSubtext(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child:                 Text(
                  '${AppLocalizations.of(context).translate('voice_select_location')} "$query"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: voiceText(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              // Scrollable list — prevents overflow and keeps within bounds
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...results.take(5).map((place) => Container(
                        color: voiceBg(context),
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: kPurple,
                          ),
                          title: Text(
                            place.localizedPlaceName().isNotEmpty
                                ? place.localizedPlaceName()
                                : place.rawPlaceName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: voiceText(context),
                            ),
                          ),
                          subtitle: place.address != null &&
                                  place.address!.isNotEmpty
                              ? Text(
                                  place.address!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: voiceSubtext(context),
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, place),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // Confirm → geocode → navigate to search with pre-filled data
  // ─────────────────────────────────────────────────────────
  bool _isConfirming = false;

  /// Parse a natural-language date string (e.g. "tomorrow", "demain",
  /// "15 juin", "2026-06-15") into a DateTime.
  DateTime? _parseVoiceDate(String raw) {
    final s = raw.trim().toLowerCase();
    final now = DateTime.now();

    // Relative keywords
    if (s.contains('demain') || s.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1);
    }
    if (s.contains('aujourd') || s.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (s.contains('après-demain') || s.contains('après demain') ||
        s.contains('after tomorrow')) {
      return DateTime(now.year, now.month, now.day + 2);
    }

    // ISO / numeric attempts
    try {
      return DateTime.parse(s);
    } catch (_) {}

    // Try common French patterns: "15/06/2026", "15-06-2026", "15 juin 2026"
    final frPattern = RegExp(r'(\d{1,2})\s*[-/\s]\s*(\d{1,2}|\w+)\s*[-/\s]\s*(\d{4})');
    final frMatch = frPattern.firstMatch(s);
    if (frMatch != null) {
      try {
        final d = int.parse(frMatch.group(1)!);
        final y = int.parse(frMatch.group(3)!);
        final mStr = frMatch.group(2)!;
        int m;
        if (RegExp(r'^\d+$').hasMatch(mStr)) {
          m = int.parse(mStr);
        } else {
          const months = {
            'janvier': 1, 'février': 2, 'fevrier': 2, 'mars': 3,
            'avril': 4, 'mai': 5, 'juin': 6, 'juillet': 7,
            'août': 8, 'aout': 8, 'septembre': 9, 'octobre': 10,
            'novembre': 11, 'décembre': 12, 'decembre': 12,
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
          };
          m = months[mStr] ?? 1;
        }
        return DateTime(y, m, d);
      } catch (_) {}
    }

    return null;
  }

  /// Parse a natural-language time string (e.g. "15h30", "3:30 PM",
  /// "15:00", "15h") into a TimeOfDay.
  TimeOfDay? _parseVoiceTime(String raw) {
    final s = raw.trim().toLowerCase().replaceAll('h', ':');

    // Handle "3:30 PM" / "3:30 pm" / "3 PM"
    bool isPm = s.contains('pm') || s.contains('soir') || s.contains('après-midi');
    bool isAm = s.contains('am') || s.contains('matin') || s.contains('du matin');
    final clean = s.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = clean.split(':');

    if (parts.isEmpty || parts[0].isEmpty) return null;
    try {
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 && parts[1].isNotEmpty
          ? int.parse(parts[1])
          : 0;

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onConfirmBooking() async {
    if (_isConfirming || _isLoading) return;
    setState(() {
      _isConfirming = true;
      _isLoading = true;
    });

    try {
      final geocoding = GeocodingService();
      final locale = Localizations.localeOf(context).languageCode;

      // ── 1. Resolve pickup (departure) ──────────────────────
      final isCurrentLoc =
          _departure == null ||
          _departure!.isEmpty ||
          _departure == 'current_location';

      GeocodingPlace? pickupPlace;
      double? pickupLat;
      double? pickupLon;
      String? pickupAddress;

      if (isCurrentLoc) {
        // Pre-fetch GPS coordinates BEFORE navigating
        final pos = await GpsService.getAccuratePosition();
        if (!mounted) return;
        if (pos == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get your current location. Please check GPS.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        pickupLat = pos.latitude;
        pickupLon = pos.longitude;

        // Try to reverse-geocode the current location for a human-readable name
        try {
          final revResults = await geocoding.searchPlaces(
            '${pos.latitude},${pos.longitude}',
            language: locale,
          );
          if (revResults.isNotEmpty) {
            final placeName = revResults.first.localizedPlaceName();
            if (placeName.isNotEmpty) {
              pickupAddress = placeName;
              voiceLog('GPS', 'Current location address: $pickupAddress');
            } else {
              pickupAddress = 'current_location';
            }
          } else {
            pickupAddress = 'current_location';
          }
        } catch (e) {
          voiceLog('GPS', 'Reverse geocoding failed: $e');
          pickupAddress = 'current_location';
        }
      } else {
        // Geocode explicit pickup address — use disambiguation for ambiguous results
        final results = await geocoding.searchPlaces(
          _departure!,
          language: locale,
        );
        if (!mounted) return;
        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find pickup location. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        // If multiple results, let user pick the correct one
        pickupPlace = results.length > 1
            ? await _showDisambiguationSheet(_departure!, results)
            : results.first;
        if (!mounted) return;
        if (pickupPlace == null || !pickupPlace.hasValidCoordinates) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find pickup location. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        pickupLat = pickupPlace.latitude;
        pickupLon = pickupPlace.longitude;
        pickupAddress = pickupPlace.localizedPlaceName().isNotEmpty
            ? pickupPlace.localizedPlaceName()
            : (_departure ?? '');
      }

      // ── 3. Geocode dropoff with disambiguation ─────────────
      final dropoffResults = await geocoding.searchPlaces(
        _destination!,
        language: locale,
      );
      if (!mounted) return;
      if (dropoffResults.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find destination. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      GeocodingPlace? dropoffPlace = dropoffResults.length > 1
          ? await _showDisambiguationSheet(_destination!, dropoffResults)
          : dropoffResults.first;
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

      // ── 4. Parse date/time ─────────────────────────────────
      DateTime? pickedDate;
      TimeOfDay? pickedTime;
      if (_date != null && _date!.isNotEmpty) {
        pickedDate = _parseVoiceDate(_date!);
      }
      if (_time != null && _time!.isNotEmpty) {
        pickedTime = _parseVoiceTime(_time!);
      }

      // If the AI didn't provide a date, default to today
      pickedDate ??= DateTime.now();

      // Validate: we must have a time to proceed
      if (pickedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please specify a time for the trip.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Fallback: if the geocoded name is empty, use the raw AI string
      final dropoffName = dropoffPlace.localizedPlaceName().isNotEmpty
          ? dropoffPlace.localizedPlaceName()
          : (_destination ?? '');

      voiceLog('NAVIGATE', 'pickup=$pickupLat,$pickupLon  dropoff=${dropoffPlace.latitude},${dropoffPlace.longitude}  date=$pickedDate  time=$pickedTime');

      // ── 5. Navigate with REAL coordinates ──────────────────
      Navigator.pushReplacementNamed(
        context,
        '/nextdestinationsearch',
        arguments: {
          'pickupPlace': pickupPlace,
          'dropoffPlace': dropoffPlace,
          'pickupAddress': pickupAddress,
          'dropoffAddress': dropoffName,
          'pickupLat': pickupLat,
          'pickupLon': pickupLon,
          'dropoffLat': dropoffPlace.latitude,
          'dropoffLon': dropoffPlace.longitude,
          'date': pickedDate,
          'time': pickedTime,
          'useCurrentLocation': isCurrentLoc,
        },
      );
    } catch (e) {
      voiceLog('CONFIRM_ERROR', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('voice_error_prefix')} ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
          _isLoading = false;
        });
      }
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
      body: Stack(
        children: [
          SafeArea(
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
          // Loading overlay while geocoding / disambiguating
          if (_isLoading)
            Container(
              color: voiceBg(context).withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: kPurple,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).translate('voice_searching_locations'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: voiceText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
