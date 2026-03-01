import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'saved_places_model.dart';
import 'add_place_page.dart';

class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  final List<SavedPlace> _places = [];

  Future<void> _goToAdd() async {
    final result = await Navigator.push<SavedPlace>(
      context,
      MaterialPageRoute(builder: (_) => const AddPlacePage()),
    );
    if (result != null) setState(() => _places.add(result));
  }

  Future<void> _goToEdit(SavedPlace place) async {
    final result = await Navigator.push<SavedPlace>(
      context,
      MaterialPageRoute(builder: (_) => AddPlacePage(existing: place)),
    );
    if (result != null) {
      setState(() {
        final i = _places.indexWhere((p) => p.id == place.id);
        if (i != -1) _places[i] = result;
      });
    }
  }

  void _delete(String id) =>
      setState(() => _places.removeWhere((p) => p.id == id));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 22,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('saved_places'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: _places.isEmpty
                  ? _EmptyState(onAdd: _goToAdd)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      itemCount: _places.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PlaceTile(
                        place: _places[i],
                        onEdit: () => _goToEdit(_places[i]),
                        onDelete: () => _delete(_places[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── "New address" button ────────────────────────────────────
      floatingActionButton: _places.isNotEmpty
          ? GestureDetector(
              onTap: _goToAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      t('new_address'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ── Place tile ────────────────────────────────────────────────────────────────

class _PlaceTile extends StatelessWidget {
  final SavedPlace place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaceTile({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(place.type.icon, color: AppColors.primaryPurple, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.label, style: AppTextStyles.settingsItem(context)),
                    if (place.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place.subtitle,
                        style: AppTextStyles.bodySmall(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.subtext(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.iconBg(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_outlined, size: 40, color: AppColors.primaryPurple),
          ),
          const SizedBox(height: 18),
          Text(t('no_saved_addresses'), style: AppTextStyles.bodyLarge(context)),
          const SizedBox(height: 6),
          Text(
            t('no_saved_addresses_subtitle'),
            style: AppTextStyles.bodySmall(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                t('new_address'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}