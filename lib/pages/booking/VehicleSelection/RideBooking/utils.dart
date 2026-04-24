/// Combine city and country into a single "City, Country" subtitle string,
/// skipping blank parts.
String cityCountry(String city, String country) {
  return [city, country].where((p) => p.isNotEmpty).join(', ');
}
