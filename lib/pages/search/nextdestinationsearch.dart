import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../services/mapbox_service.dart';

class NextDestinationSearch extends StatelessWidget {
  final VoidCallback? onSelectOnMap;
  final List<MapboxPlace> suggestions;
  final void Function(MapboxPlace)? onSuggestionTap;

  const NextDestinationSearch({
    super.key,
    this.onSelectOnMap,
    this.suggestions = const [],
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      children: [
        // ── Suggestions (max 4, visible only while typing) ──
        if (suggestions.isNotEmpty) ...[
          ...suggestions
              .take(4)
              .map(
                (item) => Column(
                  children: [
                    _SuggestionTile(
                      item: item,
                      onTap: () => onSuggestionTap?.call(item),
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 64,
                      color: AppColors.border(context),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
        ],

        // ── Static action tiles ──
        _ActionTile(
          icon: Icons.map_outlined,
          title: t.translate('select_on_map'),
          subtitle: t.translate('select_on_map_sub'),
          onTap: onSelectOnMap ?? () {},
        ),
      ],
    );
  }
}

// ── Suggestion tile ───────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final MapboxPlace item;
  final VoidCallback onTap;

  const _SuggestionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.categoryIcon,
                size: 22,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.placeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.fullAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtext(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.primaryPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtext(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}
