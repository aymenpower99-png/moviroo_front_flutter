import 'dart:convert';
import 'package:flutter/material.dart';
import '../pages/tabs [passenger]/support/help_center_models.dart';
import 'auth/auth_http.dart';

/// Fetches Help Center data from the backend.
///
/// Uses a static in-memory TTL cache (5 min) so that subsequent opens of
/// the Support page or Category page are instant — no spinner on re-entry.
class HelpCenterService {
  final String lang;

  const HelpCenterService({this.lang = 'en'});

  // ── Static in-memory cache ────────────────────────────────────────────────

  static List<HelpArticle>? _cachedArticles;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Synchronously returns the 6 categories from cache (null if cache is cold).
  /// Use this in initState to skip the loading spinner on re-entry.
  static List<HelpCategory>? get cachedCategories {
    if (_cachedArticles == null) return null;
    return _fixedCategories
        .map((def) => HelpCategory(
              id: def.key,
              name: def.label,
              icon: iconForCategory(def.key),
              articleCount:
                  _cachedArticles!.where((a) => a.categoryId == def.key).length,
            ))
        .toList();
  }

  /// Synchronously returns articles for [categoryId] from cache (null if cold).
  static List<HelpArticle>? cachedArticlesByCategory(String categoryId) {
    if (_cachedArticles == null) return null;
    return _cachedArticles!.where((a) => a.categoryId == categoryId).toList();
  }

  // ── Static category definitions ───────────────────────────────────────────

  static const List<_CategoryDef> _fixedCategories = [
    _CategoryDef(key: 'account',   label: 'Account'),
    _CategoryDef(key: 'payments',  label: 'Payments'),
    _CategoryDef(key: 'trips',     label: 'Trips'),
    _CategoryDef(key: 'safety',    label: 'Safety'),
    _CategoryDef(key: 'technical', label: 'Technical Issues'),
    _CategoryDef(key: 'other',     label: 'Other'),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  Future<List<HelpCategory>> fetchCategories() async {
    final counts = await _fetchCountsPerCategory();
    return _fixedCategories
        .map((def) => HelpCategory(
              id: def.key,
              name: def.label,
              icon: iconForCategory(def.key),
              articleCount: counts[def.key] ?? 0,
            ))
        .toList();
  }

  Future<List<HelpArticle>> fetchArticlesByCategory(String categoryId) async {
    final all = await _fetchAllFromBackend();
    return all.where((a) => a.categoryId == categoryId).toList();
  }

  Future<List<HelpArticle>> fetchAllArticles() async {
    return _fetchAllFromBackend();
  }

  // ── Icon mapping ──────────────────────────────────────────────────────────

  static IconData iconForCategory(String key) {
    switch (key) {
      case 'account':   return Icons.manage_accounts_rounded;
      case 'payments':  return Icons.credit_card_rounded;
      case 'trips':     return Icons.location_on_rounded;
      case 'safety':    return Icons.health_and_safety_rounded;
      case 'technical': return Icons.build_rounded;
      case 'other':
      default:          return Icons.grid_view_rounded;
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> _fetchCountsPerCategory() async {
    try {
      final articles = await _fetchAllFromBackend();
      final counts = <String, int>{};
      for (final a in articles) {
        counts[a.categoryId] = (counts[a.categoryId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('HelpCenterService._fetchCountsPerCategory error: $e');
      return {};
    }
  }

  /// Returns cached articles instantly if fresh; otherwise fetches from API.
  Future<List<HelpArticle>> _fetchAllFromBackend() async {
    // Return cache if still fresh
    if (_cachedArticles != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl) {
      return _cachedArticles!;
    }

    try {
      final res = await AuthHTTP.authenticatedGet('/help-center?lang=$lang');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        _cachedArticles = list
            .map((j) => HelpArticle.fromJson(j as Map<String, dynamic>))
            .toList();
        _cacheTime = DateTime.now();
        return _cachedArticles!;
      }
    } catch (e) {
      debugPrint('HelpCenterService._fetchAllFromBackend error: $e');
    }
    return _cachedArticles ?? [];   // return stale cache on error rather than []
  }
}

// ── Internal helper ───────────────────────────────────────────────────────────

class _CategoryDef {
  final String key;
  final String label;
  const _CategoryDef({required this.key, required this.label});
}


