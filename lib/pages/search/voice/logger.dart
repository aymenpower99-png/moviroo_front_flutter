import 'dart:convert';

// ─────────────────────────────────────────────────────────────
// Debug logger — visible dans le terminal flutter run
// ─────────────────────────────────────────────────────────────
void appLog(String tag, Object? msg) {
  // ignore: avoid_print
  print('\n╔══ [MOVIROO/$tag] ══════════════════════════');
  // ignore: avoid_print
  print('║  $msg');
  // ignore: avoid_print
  print('╚═══════════════════════════════════════════\n');
}

void appLogJson(String tag, Map<String, dynamic> json) {
  final encoder = const JsonEncoder.withIndent('  ');
  // ignore: avoid_print
  print('\n╔══ [MOVIROO/$tag] ══════════════════════════');
  for (final line in encoder.convert(json).split('\n')) {
    // ignore: avoid_print
    print('║  $line');
  }
  // ignore: avoid_print
  print('╚═══════════════════════════════════════════\n');
}
