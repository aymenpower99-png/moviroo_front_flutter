import 'dart:convert';
import 'package:flutter/material.dart';
import '../pages/tabs [passenger]/support/help_center_models.dart';
import 'auth/auth_http.dart';

/// Fetches Help Center data from the backend.
///
/// The 6 category cards are STATIC — they always render.
/// Only [articleCount] is dynamic, fetched from the backend by counting
/// published articles per categoryKey.
///
/// Endpoints used (JWT-authenticated):
///   GET /help-center?lang=en  → all published articles (used to count per category)
class HelpCenterService {
  /// Language to request from the backend (defaults to English).
  final String lang;

  const HelpCenterService({this.lang = 'en'});

  // ── Static category definitions ───────────────────────────────────────────

  /// The 6 fixed categories. Order and icons never change.
  static const List<_CategoryDef> _fixedCategories = [
    _CategoryDef(key: 'account',   label: 'Account'),
    _CategoryDef(key: 'payments',  label: 'Payments'),
    _CategoryDef(key: 'trips',     label: 'Trips'),
    _CategoryDef(key: 'safety',    label: 'Safety'),
    _CategoryDef(key: 'technical', label: 'Technical Issues'),
    _CategoryDef(key: 'other',     label: 'Other'),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Always returns all 6 category cards.
  /// Article counts are fetched live from the backend; 0 is shown if the
  /// backend is unreachable or a category has no published articles yet.
  Future<List<HelpCategory>> fetchCategories() async {
    // Fetch live article counts, fallback to empty map on error.
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

  /// Returns all published articles for [categoryId].
  Future<List<HelpArticle>> fetchArticlesByCategory(String categoryId) async {
    final all = await _fetchAllFromBackend();
    return all.where((a) => a.categoryId == categoryId).toList();
  }

  /// Returns every published article (used by "View All").
  Future<List<HelpArticle>> fetchAllArticles() async {
    return _fetchAllFromBackend();
  }

  // ── Icon mapping ──────────────────────────────────────────────────────────

  /// Maps a backend category key to a Flutter [IconData].
  static IconData iconForCategory(String key) {
    switch (key) {
      case 'account':
        return Icons.manage_accounts_rounded;
      case 'payments':
        return Icons.credit_card_rounded;
      case 'trips':
        return Icons.location_on_rounded;
      case 'safety':
        return Icons.health_and_safety_rounded;
      case 'technical':
        return Icons.build_rounded;
      case 'other':
      default:
        return Icons.grid_view_rounded;
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Fetches all articles and returns a map of categoryKey → count.
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

  /// Calls GET /help-center?lang= and parses the article list.
  Future<List<HelpArticle>> _fetchAllFromBackend() async {
    try {
      final res = await AuthHTTP.authenticatedGet('/help-center?lang=$lang');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((j) => HelpArticle.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('HelpCenterService._fetchAllFromBackend error: $e');
    }
    return [];
  }
}

// ── Internal helper ───────────────────────────────────────────────────────────

/// Lightweight struct for the static category definitions.
class _CategoryDef {
  final String key;
  final String label;
  const _CategoryDef({required this.key, required this.label});
}

