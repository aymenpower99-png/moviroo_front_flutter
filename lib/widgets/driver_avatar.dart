import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/config/app_config.dart';
import '../services/driver_profile_cache.dart';

/// A shared driver avatar widget that eliminates the "initials → photo" flash.
///
/// Rules:
/// • No photo URL  → shows initials immediately.
/// • Photo URL present and cached  → shows photo immediately (no placeholder).
/// • Photo URL present but not cached yet → shows a subtle shimmer/empty circle,
///   NOT initials.  This prevents the visible flash.
/// • Image load failure → fades to initials.
class DriverAvatar extends StatefulWidget {
  final String? photoUrl;
  final String? driverId;
  final String name;
  final double size;
  final double borderRadius;
  final BoxShape shape;
  final Color? backgroundColor;
  final Color? textColor;
  final Border? border;

  const DriverAvatar({
    super.key,
    this.photoUrl,
    this.driverId,
    required this.name,
    this.size = 44,
    this.borderRadius = 14,
    this.shape = BoxShape.circle,
    this.backgroundColor,
    this.textColor,
    this.border,
  });

  @override
  State<DriverAvatar> createState() => _DriverAvatarState();
}

class _DriverAvatarState extends State<DriverAvatar> {
  String? _frozenUrl; // once set to non-empty, we don't change it until dispose

  @override
  void initState() {
    super.initState();
    final initial = _resolveUrl();
    if (initial != null && initial.isNotEmpty) {
      _frozenUrl = initial;
    }
  }

  @override
  void didUpdateWidget(covariant DriverAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only set once. If we already have a non-empty URL, do not update mid-session.
    if (_frozenUrl == null || _frozenUrl!.isEmpty) {
      final next = _resolveUrl();
      if (next != null && next.isNotEmpty) {
        setState(() => _frozenUrl = next);
      }
    }
  }

  String? _resolveUrl() {
    // Prefer explicit prop, then cache lookup by driverId
    final raw = (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
        ? widget.photoUrl!
        : (widget.driverId != null
              ? (DriverProfileCache.instance.getLogoUrl(widget.driverId!) ?? '')
              : '');
    if (raw.isEmpty) return null;
    return _absoluteUrl(raw);
  }

  String _absoluteUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = AppConfig.wsBaseUrl;
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final usedUrl = _frozenUrl; // snapshot
    final hasPhoto = usedUrl != null && usedUrl.isNotEmpty;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.shape,
        color: widget.backgroundColor ?? _defaultBg(context),
        border: widget.border,
        borderRadius: widget.shape == BoxShape.rectangle
            ? BorderRadius.circular(widget.borderRadius)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: usedUrl,
              fit: BoxFit.cover,
              cacheKey: widget.driverId != null
                  ? 'driver:${widget.driverId}'
                  : null,
              // ZERO fade — avoid visible change on every mount
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) =>
                  _PhotoShimmer(size: widget.size, shape: widget.shape),
              errorWidget: (context, url, error) => _InitialsFallback(
                name: widget.name,
                size: widget.size,
                textColor: widget.textColor,
              ),
            )
          : _InitialsFallback(
              name: widget.name,
              size: widget.size,
              textColor: widget.textColor,
            ),
    );
  }

  Color _defaultBg(BuildContext context) {
    // Use a subtle purple tint that matches the app theme
    return const Color(0xFF7C3AED).withValues(alpha: 0.10);
  }
}

// ── Subtle shimmer when photo is loading ────────────────────────────────────

class _PhotoShimmer extends StatelessWidget {
  final double size;
  final BoxShape shape;

  const _PhotoShimmer({required this.size, required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
      ),
    );
  }
}

// ── Initials fallback (only when no photo or on error) ─────────────────────

class _InitialsFallback extends StatelessWidget {
  final String name;
  final double size;
  final Color? textColor;

  const _InitialsFallback({
    required this.name,
    required this.size,
    this.textColor,
  });

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r"\s+"))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final letters = (first + last).toUpperCase();
    return letters.isNotEmpty ? letters : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(name),
        style: TextStyle(
          color: textColor ?? const Color(0xFF7C3AED),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
