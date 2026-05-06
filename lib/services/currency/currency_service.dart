import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Currency metadata ─────────────────────────────────────────────────────────

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class CurrencyService extends ChangeNotifier {
  CurrencyService._();

  static final CurrencyService instance = CurrencyService._();

  // ── Currency list (shared with currency_page UI) ───────────────────────────
  static const List<CurrencyInfo> currencies = [
    CurrencyInfo(code: 'TND', name: 'Tunisian Dinar',  symbol: 'TND'),
    CurrencyInfo(code: 'USD', name: 'US Dollar',        symbol: '\$'),
    CurrencyInfo(code: 'EUR', name: 'Euro',             symbol: '€'),
    CurrencyInfo(code: 'GBP', name: 'British Pound',    symbol: '£'),
    CurrencyInfo(code: 'DZD', name: 'Algerian Dinar',   symbol: 'DZD'),
    CurrencyInfo(code: 'LYD', name: 'Libyan Dinar',     symbol: 'LYD'),
    CurrencyInfo(code: 'MAD', name: 'Moroccan Dirham',  symbol: 'MAD'),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal',      symbol: 'SAR'),
    CurrencyInfo(code: 'AED', name: 'UAE Dirham',       symbol: 'AED'),
    CurrencyInfo(code: 'EGP', name: 'Egyptian Pound',   symbol: 'EGP'),
  ];

  // ── Persistent state ───────────────────────────────────────────────────────
  String _selectedCode = 'TND';
  String get selectedCode => _selectedCode;

  CurrencyInfo get selected => currencies.firstWhere(
        (c) => c.code == _selectedCode,
        orElse: () => currencies.first,
      );

  // ── Static in-memory rate cache (shared across navigations) ───────────────
  // Static fields survive screen pushes/pops — no re-fetch on every open.
  static Map<String, double>? _cachedRates;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(hours: 24);

  static const String _prefsCodeKey   = 'currency_code';
  static const String _prefsRatesJson = 'currency_rates_json';
  static const String _prefsRatesTime = 'currency_rates_time_ms';

  bool get ratesReady => _cachedRates != null;

  // ── Init — call once in main() before runApp ───────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore persisted selected code
    _selectedCode = prefs.getString(_prefsCodeKey) ?? 'TND';

    // Restore persisted rates if still within TTL
    final ratesJson = prefs.getString(_prefsRatesJson);
    final cacheMs   = prefs.getInt(_prefsRatesTime);
    if (ratesJson != null && cacheMs != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheMs);
      if (DateTime.now().difference(cacheTime) < _cacheTtl) {
        _cachedRates = _parseRates(ratesJson);
        _cacheTime   = cacheTime;
        return; // Cache fresh — skip network
      }
    }

    // Fetch in background; format() falls back to TND until rates arrive
    _fetchRates();
  }

  // ── Select currency ────────────────────────────────────────────────────────
  Future<void> setCode(String code) async {
    if (_selectedCode == code) return;
    _selectedCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsCodeKey, code);
  }

  // ── Format ────────────────────────────────────────────────────────────────

  /// Converts [amountTnd] (base = TND) to the selected currency.
  /// Synchronous — falls back to TND display if rates not yet loaded.
  String format(double amountTnd) {
    final rate = _cachedRates?[_selectedCode] ?? 1.0;
    return _fmt(amountTnd * rate);
  }

  /// Returns `'-- <code>'` when amount is null or zero.
  String formatOrDash([double? amountTnd]) {
    if (amountTnd == null || amountTnd == 0) return '-- $_selectedCode';
    return format(amountTnd);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  String _fmt(double converted) {
    const wholeOnly = {'TND', 'DZD', 'EGP', 'LYD'};
    final decimals  = wholeOnly.contains(_selectedCode) ? 0 : 2;
    final amount    = converted.toStringAsFixed(decimals);

    switch (_selectedCode) {
      case 'USD': return '\$$amount';
      case 'EUR': return '€$amount';
      case 'GBP': return '£$amount';
      default:    return '$amount ${selected.symbol}';
    }
  }

  Future<void> _fetchRates() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/TND'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body  = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = body['rates'] as Map<String, dynamic>;
        _cachedRates = rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
        _cacheTime   = DateTime.now();
        final prefs  = await SharedPreferences.getInstance();
        await prefs.setString(_prefsRatesJson, jsonEncode(_cachedRates));
        await prefs.setInt(_prefsRatesTime, _cacheTime!.millisecondsSinceEpoch);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CurrencyService] Rate fetch failed: $e');
    }
  }

  static Map<String, double> _parseRates(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
