import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading widget for tracking page bottom sheet.
///
/// The panel background is rendered OUTSIDE the shimmer so the shimmer
/// only tints the individual placeholder shapes, creating a clean
/// “wave across shapes” effect instead of one gray slab.
class TrackingSkeleton extends StatelessWidget {
  const TrackingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Drag handle (outside shimmer so it stays static) ──
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // ── Shimmer wraps ONLY the placeholder shapes ──
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1500),
          child: const _SkeletonShapes(),
        ),
      ],
    );
  }
}

/// Placeholder shapes that shimmer together.
/// Mirrors the exact section order and spacing of the real BottomPanel.
class _SkeletonShapes extends StatelessWidget {
  const _SkeletonShapes();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. ETA row ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "12 min left"
                _SkeletonBar(height: 26, width: 140, radius: 6),
                const SizedBox(height: 6),
                // Status subtitle
                _SkeletonBar(height: 12, width: 180, radius: 4),
              ],
            ),
            // Arrival time
            _SkeletonBar(height: 26, width: 80, radius: 6),
          ],
        ),
        const SizedBox(height: 20),

        // ── 2. Progress bar ────────────────────────────────────
        _SkeletonBar(
          height: 6,
          width: double.infinity,
          radius: 3,
        ),
        const SizedBox(height: 20),

        // ── 3. Driver row ──────────────────────────────────────
        Row(
          children: [
            // Avatar
            _SkeletonCircle(diameter: 52),
            const SizedBox(width: 12),
            // Name + vehicle/plate + rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(height: 16, width: 120, radius: 4),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Vehicle/plate bar
                      _SkeletonBar(height: 12, width: 100, radius: 4),
                      const SizedBox(width: 8),
                      // Rating star + number
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SkeletonCircle(diameter: 10),
                          const SizedBox(width: 4),
                          _SkeletonBar(height: 10, width: 24, radius: 2),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Phone + chat buttons
            _SkeletonRoundedSquare(size: 38, radius: 10),
            const SizedBox(width: 10),
            _SkeletonRoundedSquare(size: 38, radius: 10),
          ],
        ),
        const SizedBox(height: 20),

        // ── 4. Pickup / Drop-off rows ──────────────────────────
        _RoutePlaceholder(),
        const SizedBox(height: 12),
        _RoutePlaceholder(),
        const SizedBox(height: 24),

        // ── 5. Stage timeline ────────────────────────────────
        _TimelinePlaceholder(),
      ],
    );
  }
}

// ── Individual skeleton primitives ─────────────────────────────────

class _SkeletonBar extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  const _SkeletonBar({
    required this.height,
    required this.width,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double diameter;
  const _SkeletonCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
    );
  }
}

class _SkeletonRoundedSquare extends StatelessWidget {
  final double size;
  final double radius;
  const _SkeletonRoundedSquare({required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Route placeholder ─────────────────────────────────────────────────

class _RoutePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 14),
        // Address bars
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBar(height: 14, width: double.infinity, radius: 4),
              const SizedBox(height: 4),
              _SkeletonBar(height: 12, width: 150, radius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Timeline placeholder ────────────────────────────────────────────

class _TimelinePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots + connecting line
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (_) => _TimelineDot()),
        ),
        const SizedBox(height: 14),
        // Status label bar
        Center(
          child: _SkeletonBar(height: 12, width: 100, radius: 4),
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
    );
  }
}
