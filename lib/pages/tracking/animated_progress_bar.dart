import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'ride_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// A progress bar that changes its animation style to match [RidePhase]:
///
/// • [RidePhase.driverOnTheWay]  — fills to [progress] + looping white shimmer
/// • [RidePhase.driverArrived]   — snaps to 100 % + green glow/pulse
/// • [RidePhase.rideInProgress]  — resets to 0, refills smoothly (shimmer)
/// • [RidePhase.rideEnded]       — fills to 100 % + green glow flash, then fades
class AnimatedRideProgressBar extends StatefulWidget {
  final RidePhase phase;

  /// 0.0 – 1.0. Only read during [RidePhase.driverOnTheWay] and
  /// [RidePhase.rideInProgress].
  final double progress;

  const AnimatedRideProgressBar({
    super.key,
    required this.phase,
    required this.progress,
  });

  @override
  State<AnimatedRideProgressBar> createState() =>
      _AnimatedRideProgressBarState();
}

class _AnimatedRideProgressBarState extends State<AnimatedRideProgressBar>
    with TickerProviderStateMixin {
  // Shimmer — driverOnTheWay & rideInProgress
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  // Glow pulse — driverArrived & rideEnded (green)
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Smooth fill
  late final AnimationController _fillCtrl;
  late final Animation<double> _fillAnim;
  double _fillFrom = 0;
  double _fillTo = 0;

  // Fade-out — rideEnded
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Flash — rideEnded
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashAnim;

  RidePhase _prevPhase = RidePhase.driverOnTheWay;

  @override
  void initState() {
    super.initState();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -0.4,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fillAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));

    _applyPhase(widget.phase, initial: true);
  }

  @override
  void didUpdateWidget(AnimatedRideProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.phase != _prevPhase) {
      _applyPhase(widget.phase);
      _prevPhase = widget.phase;
    }
  }

  void _applyPhase(RidePhase phase, {bool initial = false}) {
    switch (phase) {
      case RidePhase.driverOnTheWay:
        _shimmerCtrl.repeat();
        _pulseCtrl.stop();
        _pulseCtrl.reset();
        _fadeCtrl.reset();
        _flashCtrl.reset();
        break;

      case RidePhase.driverArrived:
        _shimmerCtrl.stop();
        _animateFill(
          from: widget.progress,
          to: 1.0,
          duration: const Duration(milliseconds: 600),
        );
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) _pulseCtrl.repeat(reverse: true);
        });
        break;

      case RidePhase.rideInProgress:
        _shimmerCtrl.repeat();
        _pulseCtrl.stop();
        _pulseCtrl.reset();
        _flashCtrl.reset();
        _fadeCtrl.reset();
        _animateFill(from: 0, to: 0, duration: const Duration(milliseconds: 1));
        break;

      case RidePhase.rideEnded:
        _shimmerCtrl.stop();
        _pulseCtrl.stop();
        _animateFill(
          from: widget.progress,
          to: 1.0,
          duration: const Duration(milliseconds: 600),
        );
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          _flashCtrl.forward().then((_) {
            if (!mounted) return;
            _flashCtrl.reverse().then((_) {
              if (!mounted) return;
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) _fadeCtrl.forward();
              });
            });
          });
        });
        break;
    }
  }

  void _animateFill({
    required double from,
    required double to,
    required Duration duration,
  }) {
    _fillFrom = from;
    _fillTo = to;
    _fillCtrl.duration = duration;
    _fillCtrl.reset();
    _fillCtrl.forward();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _fillCtrl.dispose();
    _fadeCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  double get _currentFill {
    final t = _fillAnim.value;
    return _fillFrom + (_fillTo - _fillFrom) * t;
  }

  bool get _showShimmer =>
      widget.phase == RidePhase.driverOnTheWay ||
      widget.phase == RidePhase.rideInProgress;

  bool get _showGlow =>
      widget.phase == RidePhase.driverArrived ||
      widget.phase == RidePhase.rideEnded;

  @override
  Widget build(BuildContext context) {
    final trackColor = AppColors.border(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        _shimmerAnim,
        _pulseAnim,
        _fillAnim,
        _fadeAnim,
        _flashAnim,
      ]),
      builder: (_, _) {
        final fill = _showShimmer
            ? widget
                  .progress // live value, no fill animation
            : _currentFill;

        return Opacity(
          opacity: _fadeAnim.value,
          child: SizedBox(
            height: 6,
            child: CustomPaint(
              painter: _ProgressPainter(
                fillFraction: fill.clamp(0.0, 1.0),
                shimmerPosition: _showShimmer ? _shimmerAnim.value : null,
                glowOpacity: _showGlow ? _pulseAnim.value : 0,
                flashOpacity: _flashAnim.value,
                phase: widget.phase,
                trackColor: trackColor,
              ),
              size: const Size(double.infinity, 6),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressPainter extends CustomPainter {
  final double fillFraction;
  final double? shimmerPosition;
  final double glowOpacity;
  final double flashOpacity;
  final RidePhase phase;
  final Color trackColor;

  _ProgressPainter({
    required this.fillFraction,
    required this.shimmerPosition,
    required this.glowOpacity,
    required this.flashOpacity,
    required this.phase,
    required this.trackColor,
  });

  static const _radius = Radius.circular(3);

  // Green for arrived/ended, purple for others
  Color get _glowColor =>
      (phase == RidePhase.driverArrived || phase == RidePhase.rideEnded)
      ? const Color(0xFF4ADE80)
      : AppColors.primaryPurple;

  @override
  void paint(Canvas canvas, Size size) {
    final trackRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final trackRRect = RRect.fromRectAndRadius(trackRect, _radius);

    // Track background
    canvas.drawRRect(trackRRect, Paint()..color = trackColor);

    if (fillFraction <= 0) return;

    final fillWidth = size.width * fillFraction;
    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    final fillRRect = RRect.fromRectAndRadius(fillRect, _radius);

    // Glow shadow
    if (glowOpacity > 0) {
      canvas.drawRRect(
        fillRRect.inflate(3 * glowOpacity),
        Paint()
          ..color = _glowColor.withValues(alpha: 0.55 * glowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowOpacity),
      );
    }

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
      ).createShader(fillRect);
    canvas.drawRRect(fillRRect, fillPaint);

    // Shimmer overlay
    if (shimmerPosition != null) {
      final sx = shimmerPosition! * size.width;
      final shimmerWidth = size.width * 0.35;

      canvas.save();
      canvas.clipRRect(fillRRect);
      canvas.drawRect(
        Rect.fromLTWH(sx - shimmerWidth / 2, 0, shimmerWidth, size.height),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.45),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromLTWH(
                  sx - shimmerWidth / 2,
                  0,
                  shimmerWidth,
                  size.height,
                ),
              ),
      );
      canvas.restore();
    }

    // Flash overlay (rideEnded)
    if (flashOpacity > 0) {
      canvas.save();
      canvas.clipRRect(fillRRect);
      canvas.drawRect(
        fillRect,
        Paint()..color = Colors.white.withValues(alpha: 0.6 * flashOpacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.fillFraction != fillFraction ||
      old.shimmerPosition != shimmerPosition ||
      old.glowOpacity != glowOpacity ||
      old.flashOpacity != flashOpacity ||
      old.phase != phase ||
      old.trackColor != trackColor;
}
