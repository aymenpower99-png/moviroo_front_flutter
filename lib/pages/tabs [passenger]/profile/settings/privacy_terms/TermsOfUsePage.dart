import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import 'legal_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TermsOfUsePage
//
//  Two-bar header:
//  ┌─────────────────────────────────────────────┐
//  │  ←   Terms of Use                           │  ← SliverAppBar (pinned)
//  ├─────────────────────────────────────────────┤
//  │  [logo] Moviroo              [🌐 EN ▾]      │  ← Branded sub-header
//  └─────────────────────────────────────────────┘
//
//  Supported languages: en, fr, ar, de, es, it, pt, tr
//  Loads from: data/terms/terms_patch_{lang}.json
//  Always light mode · RTL layout for Arabic
// ─────────────────────────────────────────────────────────────────────────────

class TermsOfUsePage extends StatefulWidget {
  const TermsOfUsePage({super.key});

  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  Map<String, dynamic>? _terms;
  bool _hasError = false;
  String? _selectedLang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedLang == null) {
      final lang = Localizations.localeOf(context).languageCode;
      _selectedLang = legalResolvedCode(lang);
      _loadTerms(_selectedLang!);
    }
  }

  Future<void> _loadTerms(String code) async {
    if (!mounted) return;
    setState(() { _terms = null; _hasError = false; });
    try {
      final raw  = await rootBundle
          .loadString('data/terms/terms_patch_$code.json');
      final full = json.decode(raw) as Map<String, dynamic>;
      final data = full.containsKey('terms')
          ? full['terms'] as Map<String, dynamic>
          : full;
      if (mounted) setState(() => _terms = data);
    } catch (e) {
      debugPrint('TermsOfUsePage load error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _switchLanguage(String code) {
    if (code == _selectedLang) return;
    setState(() => _selectedLang = code);
    _loadTerms(code);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final lang  = _selectedLang ?? 'en';
    final isRtl = lang == 'ar';

    if (_terms == null && !_hasError) {
      return _loadingScaffold(context, lang);
    }
    if (_hasError) {
      return _errorScaffold(context, lang);
    }

    final meta     = (_terms!['meta']     as Map<String, dynamic>?) ?? {};
    final sections = (_terms!['sections'] as List<dynamic>?)        ?? [];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _sliverAppBar(context, (meta['title'] as String?) ?? _pageTitle(lang)),
            SliverToBoxAdapter(child: _brandedHeader(context)),
            _body(context, meta, sections, isRtl),
          ],
        ),
      ),
    );
  }

  // ── Loading / error scaffolds ──────────────────────────────────────────────

  Widget _loadingScaffold(BuildContext context, String lang) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Column(
        children: [
          _appBar(context, _pageTitle(lang)),
          _brandedHeader(context),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorScaffold(BuildContext context, String lang) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Column(
        children: [
          _appBar(context, _pageTitle(lang)),
          _brandedHeader(context),
          const Expanded(
            child: Center(
              child: Text(
                'Could not load terms of use.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.lightSubtext,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar 1 — pinned SliverAppBar ────────────────────────────────────────────

  SliverAppBar _sliverAppBar(BuildContext context, String title) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.lightBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 52,
      leading: _backButton(context),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.lightText,
        ),
      ),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.lightBorder),
      ),
    );
  }

  // Non-sliver version for loading/error states
  PreferredSizeWidget _appBar(BuildContext context, String title) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.lightBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 52,
      leading: _backButton(context),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.lightText,
        ),
      ),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.lightBorder),
      ),
    );
  }

  // ── Bar 2 — branded sub-header ─────────────────────────────────────────────

  Widget _brandedHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: AppColors.lightBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        textDirection: TextDirection.ltr, // always LTR for brand bar
        children: [
          Image.asset('images/lsnn.png', width: 44, height: 44,
              fit: BoxFit.contain),
          const SizedBox(width: 12),
          const Text(
            'Moviroo',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.lightText,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          LangButton(
            current: _selectedLang ?? 'en',
            onChanged: _switchLanguage,
          ),
        ],
      ),
    );
  }

  // ── Back button ────────────────────────────────────────────────────────────

  Widget _backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }

  // ── Document body ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _body(
    BuildContext context,
    Map<String, dynamic> meta,
    List<dynamic> sections,
    bool isRtl,
  ) {
    final lang = _selectedLang ?? 'en';
    // Terms uses "effective as of" phrasing specific to terms
    final effectiveLabel = switch (lang) {
      'fr' => 'Ces conditions sont en vigueur depuis',
      'ar' => 'تسري هذه الشروط اعتباراً من',
      'de' => 'Diese Bedingungen sind gültig ab',
      'es' => 'Estos términos son efectivos desde',
      'it' => 'Questi termini sono in vigore dal',
      'pt' => 'Estes termos estão em vigor desde',
      'tr' => 'Bu koşullar şu tarihten itibaren geçerlidir:',
      _    => 'These terms are effective as of',
    };

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              (meta['title'] as String?) ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.lightText,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            if ((meta['lastUpdated'] as String? ?? '').isNotEmpty) ...[
              Text(
                '${legalLabel(LegalLabelKey.lastUpdated, lang)} '
                '${meta['lastUpdated']}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              (meta['subtitle'] as String?) ?? '',
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.lightSubtext,
                height: 1.75,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.lightBorder),
            const SizedBox(height: 24),

            ...sections.map(
              (s) => DocSection(
                data: s as Map<String, dynamic>,
                isRtl: isRtl,
              ),
            ),

            const Divider(color: AppColors.lightBorder),
            const SizedBox(height: 20),
            Center(
              child: Text(
                [
                  if ((meta['company'] as String? ?? '').isNotEmpty)
                    '© ${DateTime.now().year} ${meta['company']}. ${legalLabel(LegalLabelKey.allRights, lang)}',
                  if ((meta['effectiveDate'] as String? ?? '').isNotEmpty)
                    '$effectiveLabel ${meta['effectiveDate']}.',
                ].join('\n'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.lightSubtext,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _pageTitle(String lang) => switch (lang) {
        'fr' => "Conditions d'Utilisation",
        'ar' => 'شروط الاستخدام',
        'de' => 'Nutzungsbedingungen',
        'es' => 'Términos de Uso',
        'it' => 'Termini di Utilizzo',
        'pt' => 'Termos de Uso',
        'tr' => 'Kullanım Koşulları',
        _    => 'Terms of Use',
      };
}