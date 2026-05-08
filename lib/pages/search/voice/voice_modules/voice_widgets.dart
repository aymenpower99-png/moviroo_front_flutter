import 'package:flutter/material.dart';

import 'voice_constants.dart';

// ─────────────────────────────────────────────────────────────
// Widget Builders
// ─────────────────────────────────────────────────────────────

Widget buildTopBar({VoidCallback? onBackPressed}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildCircleBtn(
            Icons.arrow_back_rounded,
            onTap: onBackPressed,
          ),
          const Text(
            'AI TRAVEL ASSISTANT',
            style: TextStyle(
              color: kTextMain,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          buildCircleBtn(Icons.more_horiz_rounded),
        ],
      ),
    );

Widget buildCircleBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kBgCard,
          border: Border.all(color: kPurple.withOpacity(0.2)),
        ),
        child: Icon(icon, color: kTextSub, size: 18),
      ),
    );

Widget buildCenter({
  required VoicePhase phase,
  required Animation<double> pulseAnim,
  required Animation<double> ring1Anim,
  required Animation<double> ring2Anim,
  required Animation<double> ring3Anim,
  required AnimationController waveCtrl,
  required VoidCallback onMicTap,
  required Duration elapsed,
  required String statusMsg,
  required String transcript,
  required String? confirmationText,
  required String? searchQuery,
}) {
  final isActive =
      phase == VoicePhase.recording ||
      phase == VoicePhase.waitAnswer ||
      phase == VoicePhase.question;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            buildStaticRing(280, kPurple.withOpacity(0.07)),
            buildStaticRing(225, kPurple.withOpacity(0.11)),
            if (isActive) ...[
              buildAnimatedRing(ring1Anim, 210),
              buildAnimatedRing(ring2Anim, 210),
              buildAnimatedRing(ring3Anim, 210),
            ],
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPurple.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
            GestureDetector(
              onTap: onMicTap,
              child: AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: isActive ? pulseAnim.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9D8FF5), Color(0xFF6C5CE7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPurple.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: kPurple.withOpacity(0.2),
                        blurRadius: 60,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: buildMicIcon(phase),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      buildWaveform(phase: phase, waveCtrl: waveCtrl),
      const SizedBox(height: 14),
      Text(
        phaseLabel(phase),
        style: const TextStyle(
          color: kPurpleGlow,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
      const SizedBox(height: 16),
      buildMessageBubble(
        phase: phase,
        elapsed: elapsed,
        statusMsg: statusMsg,
        transcript: transcript,
        confirmationText: confirmationText,
        searchQuery: searchQuery,
      ),
    ],
  );
}

Widget buildStaticRing(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
    );

Widget buildAnimatedRing(Animation<double> anim, double maxSize) =>
    AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = anim.value;
        return Container(
          width: maxSize * v,
          height: maxSize * v,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kPurple.withOpacity((1 - v) * 0.4),
              width: 1.5,
            ),
          ),
        );
      },
    );

Widget buildMicIcon(VoicePhase phase) {
  if (phase == VoicePhase.uploading) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
    );
  }
  if (phase == VoicePhase.question) {
    return const Icon(Icons.volume_up_rounded, color: Colors.white, size: 44);
  }
  return const Icon(Icons.mic_rounded, color: Colors.white, size: 44);
}

Widget buildWaveform({
  required VoicePhase phase,
  required AnimationController waveCtrl,
}) {
  const bars = [0.4, 0.7, 1.0, 0.6, 0.9, 0.5, 0.8, 0.45, 0.75, 0.55];
  final isActive =
      phase == VoicePhase.recording ||
      phase == VoicePhase.waitAnswer ||
      phase == VoicePhase.question;
  return SizedBox(
    height: 32,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(bars.length, (i) {
        return AnimatedBuilder(
          animation: waveCtrl,
          builder: (_, __) {
            final h = isActive
                ? bars[i] *
                      (0.5 +
                          0.5 *
                              (waveCtrl.value * (i % 2 == 0 ? 1.0 : -1.0))
                                  .abs())
                : 0.3;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: 32 * h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kPink, kPurple],
                ),
              ),
            );
          },
        );
      }),
    ),
  );
}

String phaseLabel(VoicePhase phase) => switch (phase) {
      VoicePhase.recording => 'SAYING...',
      VoicePhase.waitAnswer => 'SAYING...',
      VoicePhase.uploading => 'PROCESSING...',
      VoicePhase.question => 'SAYING...',
      VoicePhase.result => 'CONFIRMED',
      VoicePhase.search => 'RESULT',
      VoicePhase.error => 'ERROR',
      _ => 'READY',
    };

Widget buildMessageBubble({
  required VoicePhase phase,
  required Duration elapsed,
  required String statusMsg,
  required String transcript,
  required String? confirmationText,
  required String? searchQuery,
}) {
  final (String text, Color highlight) = switch (phase) {
    VoicePhase.idle => ('"Welcome! Where is your next destination?"', kPink),
    VoicePhase.recording => (
      'Recording... ${elapsed.inSeconds}s',
      Colors.redAccent,
    ),
    VoicePhase.waitAnswer => (
      'Answering... ${elapsed.inSeconds}s',
      Colors.redAccent,
    ),
    VoicePhase.uploading => ('Processing your voice...', kPurpleGlow),
    VoicePhase.question => (statusMsg, kPink),
    VoicePhase.result => (
      confirmationText ?? 'Booking confirmed!',
      Colors.greenAccent,
    ),
    VoicePhase.search => (searchQuery ?? transcript, Colors.blueAccent),
    VoicePhase.error => (statusMsg, Colors.redAccent),
  };

  final words = text.split(' ');
  final lastWord = words.isNotEmpty ? words.last : '';
  final rest = words.length > 1
      ? words.sublist(0, words.length - 1).join(' ')
      : '';

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 32),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kPurple.withOpacity(0.15)),
    ),
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.5, color: kTextMain),
        children: [
          if (rest.isNotEmpty) TextSpan(text: rest),
          if (rest.isNotEmpty && lastWord.isNotEmpty)
            const TextSpan(text: ' '),
          if (lastWord.isNotEmpty)
            TextSpan(
              text: lastWord,
              style: TextStyle(color: highlight, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    ),
  );
}

Widget buildBottomArea({
  required VoicePhase phase,
  required VoidCallback onReset,
  required String? departure,
  required String? destination,
  required String? date,
  required String? time,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: Column(
        children: [
          if (phase == VoicePhase.result) ...[
            buildResultRows(
              departure: departure,
              destination: destination,
              date: date,
              time: time,
            ),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: onReset,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBgCard,
                border: Border.all(color: kPurple.withOpacity(0.25)),
              ),
              child: const Icon(Icons.close_rounded, color: kTextSub, size: 22),
            ),
          ),
        ],
      ),
    );

Widget buildResultRows({
  required String? departure,
  required String? destination,
  required String? date,
  required String? time,
}) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPurple.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          buildResultRow('From', departure, Icons.trip_origin_rounded),
          buildResultRow('To', destination, Icons.location_on_rounded),
          buildResultRow('Date', date, Icons.calendar_today_rounded),
          buildResultRow('Time', time, Icons.schedule_rounded),
        ],
      ),
    );

Widget buildResultRow(String label, String? val, IconData icon) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: kPurple),
          const SizedBox(width: 10),
          Text('$label  ', style: const TextStyle(color: kTextSub, fontSize: 13)),
          Expanded(
            child: Text(
              val ?? '—',
              style: TextStyle(
                color: val != null ? kTextMain : kTextSub,
                fontSize: 13,
                fontWeight: val != null ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
