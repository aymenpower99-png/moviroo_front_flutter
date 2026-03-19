import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LegalLocalizations
//
//  Loads legal content from:
//    • data/privacy/privacy_patch_{lang}.json  → privacy overrides
//    • data/terms/terms_patch_{lang}.json      → terms overrides
//
//  Supported languages: en, fr, ar, de, es, it, pt, tr
//  Falls back to 'en' for any unsupported locale.
//
//  Usage anywhere in the widget tree:
//    final legal   = LegalLocalizations.of(context);
//    final privacy = legal.privacy;   // Map<String, dynamic>
//    final terms   = legal.terms;     // Map<String, dynamic>
// ─────────────────────────────────────────────────────────────────────────────

class LegalLocalizations {
  LegalLocalizations(this.locale);

  final Locale locale;
  late Map<String, dynamic> _privacy;
  late Map<String, dynamic> _terms;

  // ── Supported languages ───────────────────────────────────────────────────

  static const Set<String> supportedCodes = {
    'en', 'fr', 'ar', 'de', 'es', 'it', 'pt', 'tr',
  };

  // ── Accessors ─────────────────────────────────────────────────────────────

  Map<String, dynamic> get privacy => _privacy;
  Map<String, dynamic> get terms   => _terms;

  // ── Loader ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    final code = _resolvedCode(locale.languageCode);

    final rawPrivacy = await rootBundle
        .loadString('data/privacy/privacy_patch_$code.json');
    final rawTerms = await rootBundle
        .loadString('data/terms/terms_patch_$code.json');

    _privacy = json.decode(rawPrivacy) as Map<String, dynamic>;
    _terms   = json.decode(rawTerms)   as Map<String, dynamic>;
  }

  static String _resolvedCode(String code) =>
      supportedCodes.contains(code) ? code : 'en';

  // ── InheritedWidget glue ──────────────────────────────────────────────────

  static LegalLocalizations of(BuildContext context) =>
      Localizations.of<LegalLocalizations>(context, LegalLocalizations)!;

  static const LocalizationsDelegate<LegalLocalizations> delegate =
      _LegalLocalizationsDelegate();
}

class _LegalLocalizationsDelegate
    extends LocalizationsDelegate<LegalLocalizations> {
  const _LegalLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true; // we handle fallback internally

  @override
  Future<LegalLocalizations> load(Locale locale) async {
    final l = LegalLocalizations(locale);
    await l.load();
    return l;
  }

  @override
  bool shouldReload(_LegalLocalizationsDelegate old) => false;
}