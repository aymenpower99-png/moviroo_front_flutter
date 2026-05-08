// ─────────────────────────────────────────────────────────────
// Phase — états possibles de l'assistant vocal
// ─────────────────────────────────────────────────────────────
enum VoicePhase {
  idle,
  recording,
  uploading,
  question,
  waitAnswer,
  result,
  search,
  error,
}
