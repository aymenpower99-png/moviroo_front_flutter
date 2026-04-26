import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final String duration;
  final String distance;
  final bool isSelected;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.duration,
    required this.distance,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A1228)
              : Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30, height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : Colors.white60,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(duration,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                Text(distance,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
