import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HEADER WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class AiHeader extends StatelessWidget {
  const AiHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with gradient
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO SECTION WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class AiHeroSection extends StatelessWidget {
  const AiHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title
        Text(
          'How can I help\nyou?',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle(context).copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            'Prices, routes, schedules, translation...\nI am your intelligent travel assistant.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION CARDS WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class AiActionCards extends StatelessWidget {
  final Function(String query) onCardTap;

  const AiActionCards({
    super.key,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCard(
        icon: Icons.credit_card_outlined,
        title: 'Estimate price CDG\n→ Paris center',
        query: 'Estimate the price of the trip from CDG to Paris center',
      ),
      _ActionCard(
        icon: Icons.schedule_outlined,
        title: 'Best time\nto avoid traffic\n?',
        query: 'What is the best time to avoid traffic?',
      ),
      _ActionCard(
        icon: Icons.directions_car_outlined,
        title: 'Compare sedan\nvs van for 4 people',
        query: 'Compare sedan vs van for 4 people',
      ),
      _ActionCard(
        icon: Icons.translate_outlined,
        title: 'Translate: I need a\npickup at terminal\n2',
        query: 'Translate: I need a pickup at terminal 2',
      ),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildActionCard(
          context,
          card: card,
          onTap: () => onCardTap(card.query),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required _ActionCard card,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(context),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                card.icon,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ),
            
            const Spacer(),
            
            // Title
            Text(
              card.title,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INPUT SECTION WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class AiInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const AiInputSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        border: Border(
          top: BorderSide(
            color: AppColors.border(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: AppTextStyles.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.subtext(context),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send button
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIVATE DATA CLASS
// ═══════════════════════════════════════════════════════════════════════════

class _ActionCard {
  final IconData icon;
  final String title;
  final String query;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.query,
  });
}