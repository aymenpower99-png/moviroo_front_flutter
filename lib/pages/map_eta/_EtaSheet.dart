import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class EtaSheet extends StatelessWidget {
  final int selectedRoute;

  const EtaSheet({super.key, required this.selectedRoute});

  static const List<Map<String, String>> _routes = [
    {'eta': '7 mins away', 'badge': 'PREMIUM',  'duration': '54 min', 'distance': '72 km',   'arrival': '14:17', 'left': '1.2 mi'},
    {'eta': '9 mins away', 'badge': 'STANDARD', 'duration': '53 min', 'distance': '71.4 km', 'arrival': '14:22', 'left': '1.4 mi'},
  ];

  @override
  Widget build(BuildContext context) {
    final route = _routes[selectedRoute];

    return DraggableScrollableSheet(
      initialChildSize: 0.22,
      minChildSize: 0.22,
      maxChildSize: 0.62,
      snap: true,
      snapSizes: const [0.22, 0.62],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bg(context).withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [

              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route['eta']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Arriving at ${route['arrival']} • ${route['left']} left',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge PREMIUM / STANDARD
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          route['badge']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Progress bar ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: selectedRoute == 0 ? 0.82 : 0.65,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7C3AED)),
                    ),
                  ),
                ),
              ),

              // ── Driver card ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _DriverRow(),
                ),
              ),

              // ── Share + Safety buttons ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.share_outlined,
                          label: 'Share Trip',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.shield_outlined,
                          label: 'Safety',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Continue button ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          AppRouter.push(context, AppRouter.rideDetails),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B30FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Driver row ────────────────────────────────────────────────────────────────
class _DriverRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.20),
          backgroundImage: const AssetImage('images/driver_avatar.png'),
          onBackgroundImageError: (_, __) {},
          child: ClipOval(
            child: Image.asset(
              'images/driver_avatar.png',
              width: 52, height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF7C3AED),
                  size: 26),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Name + car
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Alexander Wright',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(width: 6),
                  const Text('⭐', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text('4.9',
                      style: TextStyle(
                          color: Colors.amber.shade400,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 3),
              Text('Tesla Model S  •  White  •  KRE 9042',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12)),
            ],
          ),
        ),

        // Chat button
        GestureDetector(
          onTap: () => AppRouter.push(context, AppRouter.chat),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.30)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF7C3AED), size: 20),
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}