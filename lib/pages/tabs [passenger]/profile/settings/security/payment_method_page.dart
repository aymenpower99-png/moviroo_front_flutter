import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import 'add_card_page.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PaymentCard {
  final String id;
  final String holder;
  final String last4;
  final String expiry;
  final CardType type;
  final bool isDefault;

  const PaymentCard({
    required this.id,
    required this.holder,
    required this.last4,
    required this.expiry,
    required this.type,
    this.isDefault = false,
  });

  PaymentCard copyWith({bool? isDefault}) => PaymentCard(
        id: id,
        holder: holder,
        last4: last4,
        expiry: expiry,
        type: type,
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

  void _setDefault(String id) {
    setState(() {
      _cards = _cards.map((c) => c.copyWith(isDefault: c.id == id)).toList();
    });
  }

  void _deleteCard(String id) {
    setState(() => _cards.removeWhere((c) => c.id == id));
  }

  Future<void> _openAddCard() async {
    final card = await Navigator.push<PaymentCard>(
      context,
      MaterialPageRoute(builder: (_) => const AddCardPage()),
    );
    if (card != null) {
      setState(() => _cards.add(card));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('Payment Methods')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    if (_cards.isNotEmpty) ...[
                      Text(
                        t('SAVED CARDS').toUpperCase(),
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
                    _InfoNote(
                      text: t(
                        'Your card details are encrypted and stored securely. We never store your full card number.',
                      ),
                    ),

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
        title: Text(t('Remove Card?'), style: AppTextStyles.bodyLarge(context)),
        content: Text(
          '${t('Remove card ending in')} ${card.last4}?',
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('Cancel'),
                style: TextStyle(color: AppColors.subtext(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
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
          color:
              card.isDefault ? AppColors.primaryPurple : AppColors.border(context),
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
                  child: _CardBrandIcon(type: card.type),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•••• •••• •••• ${card.last4}',
                          style: AppTextStyles.bodyLarge(context)),
                      const SizedBox(height: 2),
                      Text(
                        '${card.holder}  •  ${t('Expires')} ${card.expiry}',
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                ),
                if (card.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t('Default'),
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
                    label: t('Set as Default'),
                    color: AppColors.primaryPurple,
                    onTap: onSetDefault,
                  ),
                ),
              if (!card.isDefault)
                VerticalDivider(width: 1, color: AppColors.border(context)),
              Expanded(
                child: _TileAction(
                  icon: Icons.delete_outline_rounded,
                  label: t('Remove'),
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
            Text(label,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
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
        return Text('VISA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryPurple,
              letterSpacing: 1,
            ));
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
                      color: AppColors.error, shape: BoxShape.circle)),
            ),
            Positioned(
              right: 6,
              child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.9),
                      shape: BoxShape.circle)),
            ),
          ],
        );
      case CardType.amex:
        return Text('AMEX',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
              letterSpacing: 0.5,
            ));
      case CardType.other:
        return Icon(Icons.credit_card_rounded,
            color: AppColors.subtext(context), size: 20);
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
                  gradient: AppColors.purpleGradient, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Text(t('Add New Card'),
                style: AppTextStyles.bodyLarge(context)
                    .copyWith(fontWeight: FontWeight.w600)),
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
                color: AppColors.iconBg(context), shape: BoxShape.circle),
            child: const Icon(Icons.credit_card_off_rounded,
                color: AppColors.primaryPurple, size: 30),
          ),
          const SizedBox(height: 14),
          Text(t('No cards saved yet'), style: AppTextStyles.bodyLarge(context)),
          const SizedBox(height: 4),
          Text(t('Add a card to pay faster'),
              style: AppTextStyles.bodySmall(context)),
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
        color: AppColors.primaryPurple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 16, color: AppColors.primaryPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall(context)
                    .copyWith(color: AppColors.primaryPurple)),
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
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.subtext(context)),
            ),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle(context)),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}