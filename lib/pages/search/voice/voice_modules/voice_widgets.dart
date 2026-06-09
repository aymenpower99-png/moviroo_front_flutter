import 'package:flutter/material.dart';

import 'voice_constants.dart';

// ─────────────────────────────────────────────────────────────
// Widget Builders
// ─────────────────────────────────────────────────────────────

Widget buildTopBar(BuildContext context, {VoidCallback? onBackPressed}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildCircleBtn(
            context,
            Icons.arrow_back_rounded,
            onTap: onBackPressed,
          ),
          Text(
            'AI TRAVEL ASSISTANT',
            style: TextStyle(
              color: voiceText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          Opacity(
            opacity: 0,
            child: buildCircleBtn(context, Icons.more_horiz_rounded),
          ),
        ],
      ),
    );

Widget buildCircleBtn(
  BuildContext context,
  IconData icon, {
  VoidCallback? onTap,
}) => GestureDetector(
  onTap: onTap,
  child: Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: voiceSurface(context),
      border: Border.all(color: kPurple.withOpacity(0.2)),
    ),
    child: Icon(icon, color: voiceSubtext(context), size: 18),
  ),
);

Widget buildCenter(
  BuildContext context, {
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
      ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 280,
          minHeight: 240,
          maxHeight: 280,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isActive) ...[
              buildStaticRing(240, kPurple.withOpacity(0.07)),
              buildStaticRing(190, kPurple.withOpacity(0.11)),
              buildAnimatedRing(ring1Anim, 210),
              buildAnimatedRing(ring2Anim, 210),
              buildAnimatedRing(ring3Anim, 210),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kPurple.withOpacity(0.18), Colors.transparent],
                  ),
                ),
              ),
            ],
            GestureDetector(
              onTap: onMicTap,
              child: AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: isActive ? pulseAnim.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7C3AED),
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
          color: kPurple,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
      const SizedBox(height: 16),
      buildMessageBubble(
        context,
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
  if (phase == VoicePhase.waitAnswer) {
    return const Icon(Icons.hearing_rounded, color: Colors.white, size: 44);
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
        if (!isActive) {
          // Static and flat by default — zero animation
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFFA855F7),
            ),
          );
        }
        return AnimatedBuilder(
          animation: waveCtrl,
          builder: (_, __) {
            final h =
                bars[i] *
                (0.5 +
                    0.5 * (waveCtrl.value * (i % 2 == 0 ? 1.0 : -1.0)).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: 32 * h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFFA855F7),
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
  VoicePhase.waitAnswer => 'LISTENING...',
  VoicePhase.uploading => 'PROCESSING...',
  VoicePhase.question => 'SAYING...',
  VoicePhase.result => 'CONFIRMED',
  VoicePhase.search => 'RESULT',
  VoicePhase.error => 'ERROR',
  _ => 'TAP TO SPEAK',
};

Widget buildMessageBubble(
  BuildContext context, {
  required VoicePhase phase,
  required Duration elapsed,
  required String statusMsg,
  required String transcript,
  required String? confirmationText,
  required String? searchQuery,
}) {
  final (String text, Color highlight) = switch (phase) {
    VoicePhase.idle => ('"Welcome! Where is your next destination?"', kPurple),
    VoicePhase.recording => ('Recording...', Colors.redAccent),
    VoicePhase.waitAnswer => ('🎙 Listening... tap mic when done', kPurple),
    VoicePhase.uploading => ('Processing your voice...', kPurpleGlow),
    VoicePhase.question => (statusMsg, kPurple),
    VoicePhase.result => (
      confirmationText ?? 'Booking confirmed!',
      Colors.greenAccent,
    ),
    VoicePhase.search => (searchQuery ?? transcript, Colors.blueAccent),
    VoicePhase.error => (statusMsg, Colors.redAccent),
  };

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 32),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: voiceSurface(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kPurple.withOpacity(0.15)),
    ),
    child: phase == VoicePhase.idle
        ? RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: voiceText(context),
              ),
              children: const [
                TextSpan(text: '"Welcome! '),
                TextSpan(
                  text: 'Where is your next destination?',
                  style: TextStyle(color: kPurple, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '"'),
              ],
            ),
          )
        : RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: voiceText(context),
              ),
              children: [TextSpan(text: text)],
            ),
          ),
  );
}

Widget buildBottomArea(
  BuildContext context, {
  required VoicePhase phase,
  required VoidCallback onReset,
  required VoidCallback? onConfirm,
  required String? departure,
  required String? destination,
  required String? date,
  required String? time,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 8, top: 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (phase == VoicePhase.result) ...[
        buildResultRows(
          context,
          departure: departure,
          destination: destination,
          date: date,
          time: time,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (phase != VoicePhase.question && phase != VoicePhase.waitAnswer)
        GestureDetector(
          onTap: onReset,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: voiceSurface(context),
              border: Border.all(color: kPurple.withOpacity(0.25)),
            ),
            child: Icon(
              Icons.close_rounded,
              color: voiceSubtext(context),
              size: 22,
            ),
          ),
        ),
    ],
  ),
);

Widget buildResultRows(
  BuildContext context, {
  required String? departure,
  required String? destination,
  required String? date,
  required String? time,
}) => Container(
  margin: const EdgeInsets.symmetric(horizontal: 24),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: voiceSurface(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kPurple.withOpacity(0.15)),
  ),
  child: Column(
    children: [
      buildResultRow(
        context,
        'From',
        (departure == null ||
                departure.isEmpty ||
                departure == 'current_location')
            ? 'My Current Location'
            : departure,
        Icons.trip_origin_rounded,
      ),
      buildResultRow(context, 'To', destination, Icons.location_on_rounded),
      buildResultRow(context, 'Date', date, Icons.calendar_today_rounded),
      buildResultRow(context, 'Time', time, Icons.schedule_rounded),
    ],
  ),
);

Widget buildYouSaidCard(BuildContext context, {required String transcript}) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: voiceSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPurple.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOU SAID',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: voiceSubtext(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transcript,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: voiceText(context),
            ),
          ),
        ],
      ),
    );

Widget buildResultRow(
  BuildContext context,
  String label,
  String? val,
  IconData icon,
) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      Icon(icon, size: 15, color: kPurple),
      const SizedBox(width: 10),
      Text(
        '$label  ',
        style: TextStyle(color: voiceSubtext(context), fontSize: 13),
      ),
      Expanded(
        child: Text(
          val ?? '—',
          style: TextStyle(
            color: val != null ? voiceText(context) : voiceSubtext(context),
            fontSize: 13,
            fontWeight: val != null ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  ),
);
