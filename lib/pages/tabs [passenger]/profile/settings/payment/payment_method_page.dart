import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';
import '../../../../../../../theme/app_text_styles.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../services/ride_api/booking_api_service.dart';
import 'add_card_page.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PaymentCard {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
    id: json['id'] as String,
    brand: json['brand'] as String,
    last4: json['last4'] as String,
    expMonth: json['expMonth'] as int,
    expYear: json['expYear'] as int,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  String get expiryFormatted =>
      '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}';

  CardType get cardType {
    switch (brand.toLowerCase()) {
      case 'visa':
        return CardType.visa;
      case 'mastercard':
        return CardType.mastercard;
      case 'amex':
        return CardType.amex;
      default:
        return CardType.other;
    }
  }

  PaymentCard copyWith({bool? isDefault}) => PaymentCard(
    id: id,
    brand: brand,
    last4: last4,
    expMonth: expMonth,
    expYear: expYear,
    isDefault: isDefault ?? this.isDefault,
  );
}

enum CardType { visa, mastercard, amex, other }

// ── Page ──────────────────────────────────────────────────────────────────────

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  List<PaymentCard> _cards = [];
  bool _isLoading = false;
  final _api = BookingApiService();

  @override
  void initState() {
    super.initState();

    // 1. Populate from cache synchronously — no spinner
    final cached = _api.cachedSavedCards;
    if (cached != null) {
      _cards = cached.map(PaymentCard.fromJson).toList();
    }

    // 2. Always refresh in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCards();
    });
  }

  Future<void> _refreshCards() async {
    try {
      final raw = await _api.getSavedCards();
      if (mounted) {
        setState(() => _cards = raw.map(PaymentCard.fromJson).toList());
      }
    } catch (_) {
      // silent fail — keep showing cached/empty state
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      await _api.setDefaultCard(id);
      setState(() {
        _cards = _cards.map((c) => c.copyWith(isDefault: c.id == id)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to set default: $e')));
    }
  }

  Future<void> _deleteCard(String id) async {
    try {
      await _api.deleteCard(id);
      setState(() => _cards.removeWhere((c) => c.id == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove card: $e')));
    }
  }

  Future<void> _openAddCard() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddCardPage()),
    );
    if (added == true) _refreshCards();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('payment_methods')),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          if (_cards.isNotEmpty) ...[
                            Text(
                              t('saved_cards'),
                              style: AppTextStyles.sectionLabel(context),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(_cards.length, (i) {
                              final card = _cards[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CardTile(
                                  card: card,
                                  onSetDefault: () => _setDefault(card.id),
                                  onDelete: () => _confirmDelete(card),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],

                          if (_cards.isEmpty) _EmptyState(),

                          const SizedBox(height: 16),

                          // ── Add new card button ──
                          _AddCardButton(onTap: _openAddCard),

                          const SizedBox(height: 24),

                          // ── Security note ──
                          _InfoNote(text: t('card_security_note')),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PaymentCard card) async {
    final t = AppLocalizations.of(context).translate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('remove_card_title'),
          style: AppTextStyles.bodyLarge(context),
        ),
        content: Text(
          '${t('remove_card_ending')} ${card.last4}?',
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.subtext(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t('remove'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteCard(card.id);
  }
}

// ── Card Tile ─────────────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final PaymentCard card;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isDefault
              ? AppColors.primaryPurple
              : AppColors.border(context),
          width: card.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.iconBg(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _CardBrandIcon(type: card.cardType),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•••• •••• •••• ${card.last4}',
                        style: AppTextStyles.bodyLarge(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${card.brand[0].toUpperCase()}${card.brand.substring(1)}  •  ${t('expires')} ${card.expiryFormatted}',
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                ),
                if (card.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t('default_label'),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(context)),
          Row(
            children: [
              if (!card.isDefault)
                Expanded(
                  child: _TileAction(
                    icon: Icons.check_circle_outline_rounded,
                    label: t('set_as_default'),
                    color: AppColors.primaryPurple,
                    onTap: onSetDefault,
                  ),
                ),
              if (!card.isDefault)
                VerticalDivider(width: 1, color: AppColors.border(context)),
              Expanded(
                child: _TileAction(
                  icon: Icons.delete_outline_rounded,
                  label: t('remove'),
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Brand Icon ───────────────────────────────────────────────────────────

class _CardBrandIcon extends StatelessWidget {
  final CardType type;
  const _CardBrandIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case CardType.visa:
        return Text(
          'VISA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryPurple,
            letterSpacing: 1,
          ),
        );
      case CardType.mastercard:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case CardType.amex:
        return Text(
          'AMEX',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.success,
            letterSpacing: 0.5,
          ),
        );
      case CardType.other:
        return Icon(
          Icons.credit_card_rounded,
          color: AppColors.subtext(context),
          size: 20,
        );
    }
  }
}

// ── Add Card Button ───────────────────────────────────────────────────────────

class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Text(
              t('add_new_card'),
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.iconBg(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_off_rounded,
              color: AppColors.primaryPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(t('no_cards_saved'), style: AppTextStyles.bodyLarge(context)),
          const SizedBox(height: 4),
          Text(t('add_card_faster'), style: AppTextStyles.bodySmall(context)),
        ],
      ),
    );
  }
}

// ── Info Note ─────────────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _SubPageTopBar extends StatelessWidget {
  final String title;
  const _SubPageTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
