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