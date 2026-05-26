/// Clean up raw addresses coming from OSM / Mapbox / Nominatim.
///
/// Removes:
/// - postal codes
/// - country names (EN/FR/AR)
/// - administrative prefixes
/// - duplicated commas/spaces
///
/// Examples:
/// "Bir Bourgeba, Hammamet, 8028, Tunisia"
///   -> "Bir Bourgeba, Hammamet"
///
/// "المرزقة، معتمدية الحمامات، ولاية نابل، تونس"
///   -> "المرزقة، الحمامات، نابل"
String simplifyAddress(
  String? address, {
  String defaultValue = '',
}) {
  if (address == null || address.trim().isEmpty) {
    return defaultValue;
  }

  String result = address;

  // Normalize Arabic commas
  result = result.replaceAll('،', ',');

  // Remove postal codes
  result = result.replaceAll(
    RegExp(r'\b\d{4,}\b'),
    '',
  );

  // Remove country names
  result = result.replaceAll(
    RegExp(
      r',?\s*(Tunisia|Tunisie|تونس)\s*$',
      caseSensitive: false,
    ),
    '',
  );

  // Remove admin prefixes
  result = result.replaceAll(
    RegExp(
      r'\b(ولاية|معتمدية|Gouvernorat|Delegation)\b',
      caseSensitive: false,
    ),
    '',
  );

  // Collapse duplicate commas
  result = result.replaceAll(
    RegExp(r',\s*,+'),
    ',',
  );

  // Remove extra spaces
  result = result.replaceAll(
    RegExp(r'\s{2,}'),
    ' ',
  );

  // Trim commas/spaces
  result = result
      .replaceAll(RegExp(r'^,+|,+$'), '')
      .trim();

  // Split + deduplicate segments
  final parts = result
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final unique = <String>[];

  for (final part in parts) {
    final normalized = part.toLowerCase();

    final exists = unique.any(
      (u) => u.toLowerCase() == normalized,
    );

    if (!exists) {
      unique.add(part);
    }
  }

  return unique.join(', ');
}

// ══════════════════════════════════════════════════════════════════
// LOCALE-AWARE ADDRESS BUILDER
// ══════════════════════════════════════════════════════════════════

/// Detects the primary script of a text segment.
/// Returns: 'arabic', 'latin', 'mixed', or 'unknown'
String detectScript(String text) {
  if (text.trim().isEmpty) return 'unknown';

  final arabicRange = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
  final latinRange = RegExp(r'[a-zA-Z\u00C0-\u024F]');

  final hasArabic = arabicRange.hasMatch(text);
  final hasLatin = latinRange.hasMatch(text);

  if (hasArabic && hasLatin) return 'mixed';
  if (hasArabic) return 'arabic';
  if (hasLatin) return 'latin';
  return 'unknown';
}

/// Checks if a segment's script matches the target locale.
/// - 'ar' → accepts only arabic segments
/// - 'fr'/'en' → accepts only latin segments
/// - Mixed or unknown segments are filtered out
bool _segmentMatchesLocale(String segment, String locale) {
  final script = detectScript(segment);

  if (script == 'mixed') {
    // Mixed segments (like "Bir Bouregba, معتمدية الحمامات") are the problem
    // Split by comma and check each sub-segment
    final subSegments = segment.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    // If any sub-segment matches the locale, the parent segment is partially valid
    // But we prefer to drop mixed segments entirely
    return false;
  }

  if (script == 'unknown') {
    // Numbers/punctuation only — keep for all locales
    return true;
  }

  final targetLocale = locale.toLowerCase();
  if (targetLocale == 'ar') {
    return script == 'arabic';
  } else {
    // fr, en, and all other locales → latin script
    return script == 'latin';
  }
}

/// Arabic administrative labels to strip from addresses.
const List<String> _arabicAdminLabels = [
  'ولاية',
  'معتمدية',
  'تونس',
];

/// English/French administrative labels to strip.
const List<String> _latinAdminLabels = [
  'Tunisia',
  'Tunisie',
  'Gouvernorat',
  'Governorate',
  'Delegation',
  'Délégation',
];

/// Removes administrative prefix labels from a segment.
String _stripAdminLabels(String segment) {
  String result = segment;
  for (final label in _arabicAdminLabels) {
    result = result.replaceAll(RegExp('^$label\\s+', unicode: true), '');
    result = result.replaceAll(RegExp('\\s+$label\\s*\$', unicode: true), '');
  }
  for (final label in _latinAdminLabels) {
    result = result.replaceAll(RegExp('^$label\\s+', caseSensitive: false), '');
    result = result.replaceAll(RegExp('\\s+$label\\s*\$', caseSensitive: false), '');
  }
  return result.trim();
}

/// Builds a clean, locale-aware address from structured address components.
///
/// [parts] — ordered list of address segments (most specific first).
/// [locale] — target locale: 'fr', 'en', 'ar'.
///
/// Steps:
/// 1. Strip admin labels from each segment
/// 2. Filter segments by script matching the locale
/// 3. Deduplicate
/// 4. Join with locale-appropriate separator
///
/// Example (locale='fr'):
///   parts = ['Bir Bouregba', 'معتمدية الحمامات', 'Hammamet', 'Tunisia']
///   → "Bir Bouregba, Hammamet"
///
/// Example (locale='ar'):
///   parts = ['بير بورقبة', 'Hammamet', 'الحمامات', 'تونس']
///   → "بير بورقبة، الحمامات"
String buildLocalizedAddress({
  required List<String?> parts,
  String locale = 'fr',
}) {
  final targetLocale = locale.toLowerCase();
  final isArabic = targetLocale == 'ar';
  final separator = isArabic ? '، ' : ', ';

  final cleaned = <String>[];

  for (final raw in parts) {
    if (raw == null || raw.trim().isEmpty) continue;

    // Step 1: Strip admin labels
    String segment = _stripAdminLabels(raw.trim());

    // Step 2: Remove postal codes
    segment = segment.replaceAll(RegExp(r'\b\d{4,}\b'), '');

    // Step 3: Remove country names
    segment = segment.replaceAll(
      RegExp(r',?\s*(Tunisia|Tunisie|تونس)\s*$', caseSensitive: false),
      '',
    );

    segment = segment.trim();
    if (segment.isEmpty) continue;

    // Step 4: Filter by locale script
    if (!_segmentMatchesLocale(segment, targetLocale)) {
      continue;
    }

    // Step 5: Deduplicate (case-insensitive)
    final normalized = segment.toLowerCase();
    if (!cleaned.any((c) => c.toLowerCase() == normalized)) {
      cleaned.add(segment);
    }
  }

  // Limit to max 3 segments for compactness
  return cleaned.take(3).join(separator);
}

/// Builds a localized display name from raw OSM/Nominatim display_name.
/// This is the main entry point for frontend address cleanup.
///
/// [displayName] — raw display_name from Nominatim/Mapbox.
/// [locale] — target locale: 'fr', 'en', 'ar'.
///
/// Steps:
/// 1. Split display_name by comma
/// 2. Strip admin labels
/// 3. Filter by locale script
/// 4. Deduplicate and join
String buildLocalizedDisplayName(
  String? displayName, {
  String locale = 'fr',
}) {
  if (displayName == null || displayName.trim().isEmpty) {
    return '';
  }

  // Normalize Arabic commas
  final normalized = displayName.replaceAll('،', ',');

  // Split into parts
  final parts = normalized
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  return buildLocalizedAddress(parts: parts, locale: locale);
}
