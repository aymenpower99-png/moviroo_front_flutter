import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  legal_shared.dart
//
//  Shared code used by both PrivacyPolicyPage and TermsOfUsePage:
//    • supportedLangs          — single source of truth for all 8 locales
//    • legalResolvedCode()     — fallback helper
//    • LegalLabelKey / labels  — localised UI strings
//    • LangButton              — 🌐 language switcher popup
//    • DocSection              — section renderer
//    • DocSubsection           — bullet-list sub-section renderer
// ─────────────────────────────────────────────────────────────────────────────

// ── Supported languages ───────────────────────────────────────────────────────

const Set<String> supportedLangs = {'en', 'fr', 'ar', 'de', 'es', 'it', 'pt', 'tr'};

String legalResolvedCode(String code) =>
    supportedLangs.contains(code) ? code : 'en';

// ── UI label keys ─────────────────────────────────────────────────────────────

enum LegalLabelKey { lastUpdated, allRights, effectiveAs }

String legalLabel(LegalLabelKey key, String lang) {
  return switch (key) {
    LegalLabelKey.lastUpdated => switch (lang) {
        'fr' => 'Dernière mise à jour :',
        'ar' => 'آخر تحديث:',
        'de' => 'Zuletzt aktualisiert:',
        'es' => 'Última actualización:',
        'it' => 'Ultimo aggiornamento:',
        'pt' => 'Última atualização:',
        'tr' => 'Son güncelleme:',
        _    => 'Last updated:',
      },
    LegalLabelKey.allRights => switch (lang) {
        'fr' => 'Tous droits réservés.',
        'ar' => 'جميع الحقوق محفوظة.',
        'de' => 'Alle Rechte vorbehalten.',
        'es' => 'Todos los derechos reservados.',
        'it' => 'Tutti i diritti riservati.',
        'pt' => 'Todos os direitos reservados.',
        'tr' => 'Tüm hakları saklıdır.',
        _    => 'All rights reserved.',
      },
    LegalLabelKey.effectiveAs => switch (lang) {
        'fr' => 'Cette politique est en vigueur depuis',
        'ar' => 'تسري هذه السياسة اعتباراً من',
        'de' => 'Diese Richtlinie ist gültig ab',
        'es' => 'Esta política es efectiva desde',
        'it' => 'Questa politica è in vigore dal',
        'pt' => 'Esta política está em vigor desde',
        'tr' => 'Bu politika şu tarihten itibaren geçerlidir:',
        _    => 'This policy is effective as of',
      },
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  LangButton — 🌐 language switcher
// ─────────────────────────────────────────────────────────────────────────────

class LangButton extends StatelessWidget {
  const LangButton({super.key, required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  // (code, native name, label)
  static const _langs = [
    ('en', 'English',    'EN'),
    ('fr', 'Français',   'FR'),
    ('ar', 'العربية',    'AR'),
    ('de', 'Deutsch',    'DE'),
    ('es', 'Español',    'ES'),
    ('it', 'Italiano',   'IT'),
    ('pt', 'Português',  'PT'),
    ('tr', 'Türkçe',     'TR'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      color: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      offset: const Offset(0, 44),
      itemBuilder: (_) => _langs.map((l) {
        final isActive = l.$1 == current;
        return PopupMenuItem<String>(
          value: l.$1,
          child: Row(
            children: [
              Text(
                l.$3,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppColors.primaryPurple
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.$2,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primaryPurple
                      : AppColors.lightText,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.primaryPurple),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lightBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                size: 14, color: AppColors.lightSubtext),
            const SizedBox(width: 5),
            Text(
              current.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: AppColors.lightSubtext),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DocSection
// ─────────────────────────────────────────────────────────────────────────────

class DocSection extends StatelessWidget {
  const DocSection({super.key, required this.data, required this.isRtl});

  final Map<String, dynamic> data;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final title       = (data['title']       as String?) ?? '';
    final description = (data['description'] as String?) ?? '';
    final subsections = (data['subsections'] as List<dynamic>?) ?? [];
    final note        = data['note']        as String?;

    return Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.lightText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        if (description.isNotEmpty)
          ...description.split('\n\n').map(
            (para) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                para.trim(),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.lightSubtext,
                  height: 1.75,
                ),
              ),
            ),
          ),

        if (subsections.isNotEmpty) const SizedBox(height: 4),
        ...subsections.map(
          (sub) => DocSubsection(
            data: sub as Map<String, dynamic>,
            isRtl: isRtl,
          ),
        ),

        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            note,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.lightSubtext,
              height: 1.7,
            ),
          ),
        ],

        const SizedBox(height: 28),
        const Divider(color: AppColors.lightBorder),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DocSubsection
// ─────────────────────────────────────────────────────────────────────────────

class DocSubsection extends StatelessWidget {
  const DocSubsection({super.key, required this.data, required this.isRtl});

  final Map<String, dynamic> data;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final heading = (data['heading'] as String?) ?? '';
    final items   = (data['items']   as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (heading.isNotEmpty) ...[
            Text(
              heading,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection:
                    isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      left:  isRtl ? 10 : 0,
                      right: isRtl ? 0  : 10,
                    ),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.lightSubtext,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item as String,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.lightSubtext,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}