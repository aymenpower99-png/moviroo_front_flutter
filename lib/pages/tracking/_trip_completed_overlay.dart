import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import 'ride_state.dart';

class TripCompletedOverlay extends StatelessWidget {
  final RideState rideState;
  final VoidCallback onContinue;

  const TripCompletedOverlay({
    super.key,
    required this.rideState,
    required this.onContinue,
  });

  static const _purple = AppColors.primaryPurple;
  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(green: _green),
              const SizedBox(height: 10),
              _TripRouteCard(rideState: rideState),
              const SizedBox(height: 8),
              _TripDetailsRow(rideState: rideState),
              const SizedBox(height: 8),
              _DriverRatingCard(
                driverName: rideState.driverName,
                vehicleName: rideState.vehicleName,
              ),
              const SizedBox(height: 8),
              _RewardsCard(purple: _purple),
              const SizedBox(height: 16),
              _ActionsSection(purple: _purple, onContinue: onContinue),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Color green;
  const _Header({required this.green});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFDCFCE7),
            border: Border.all(color: green.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(Icons.check_rounded, color: green, size: 36),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.translate('trip_completed'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text(context),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.translate('trip_completed_subtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.subtext(context),
          ),
        ),
      ],
    );
  }
}

// ─── Trip route (pickup → drop-off) ──────────────────────────────────────────

class _TripRouteCard extends StatelessWidget {
  final RideState rideState;
  const _TripRouteCard({required this.rideState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const purple = AppColors.primaryPurple;
    final pickup = rideState.pickupAddress.isNotEmpty
        ? rideState.pickupAddress
        : 'Pickup location';
    final dropoff = rideState.dropoffAddress.isNotEmpty
        ? rideState.dropoffAddress
        : 'Drop-off location';
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Timeline indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: purple,
                ),
              ),
              Container(width: 2, height: 34, color: AppColors.border(context)),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: purple, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RouteStop(label: l10n.translate('pickup'), address: pickup),
                const SizedBox(height: 14),
                _RouteStop(label: l10n.translate('dropoff'), address: dropoff),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip details chips (duration + distance) ─────────────────────────────────

class _TripDetailsRow extends StatelessWidget {
  final RideState rideState;
  const _TripDetailsRow({required this.rideState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const purple = AppColors.primaryPurple;
    final distance = rideState.distanceLeft.isNotEmpty
        ? rideState.distanceLeft
        : '—';
    return Row(
      children: [
        Expanded(
          child: _Chip(
            icon: Icons.timer_outlined,
            label: l10n.translate('duration'),
            value: '27 min',
            color: purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            icon: Icons.route_rounded,
            label: l10n.translate('distance'),
            value: distance,
            color: purple,
          ),
        ),
      ],
    );
  }
}

// ─── Driver + Rating card (combined) ─────────────────────────────────────────

class _DriverRatingCard extends StatefulWidget {
  final String driverName;
  final String vehicleName;
  const _DriverRatingCard({
    required this.driverName,
    required this.vehicleName,
  });

  @override
  State<_DriverRatingCard> createState() => _DriverRatingCardState();
}

class _DriverRatingCardState extends State<_DriverRatingCard> {
  int _rating = 0;
  static const _purple = AppColors.primaryPurple;
  static const _gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.iconBg(context),
                  border: Border.all(
                    color: _purple.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: _purple,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.driverName.isNotEmpty
                                ? widget.driverName
                                : 'Driver',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, color: _gold, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '4.9',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.vehicleName.isNotEmpty
                          ? widget.vehicleName
                          : 'Vehicle',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.subtext(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 12),
          // Rating label + stars
          Center(
            child: Text(
              l10n.translate('rate_your_driver'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      key: ValueKey(i < _rating),
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < _rating ? _gold : const Color(0xFFD1D5DB),
                      size: 34,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Rewards card ─────────────────────────────────────────────────────────────

class _RewardsCard extends StatelessWidget {
  final Color purple;
  const _RewardsCard({required this.purple});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const double progress = 0.40;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('points_earned'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.subtext(context),
                    ),
                  ),
                  Text(
                    '+50 points',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: purple,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                l10n.translate('moviroo_tier_go'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.border(context),
                valueColor: AlwaysStoppedAnimation<Color>(purple),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n
                  .translate('pct_to_moviroo_max')
                  .replaceAll('{pct}', '${(progress * 100).toInt()}'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppColors.subtext(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions ──────────────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  final Color purple;
  final VoidCallback onContinue;
  const _ActionsSection({required this.purple, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.translate('submit_rating'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: purple,
              side: BorderSide(color: purple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageIcon(
                  const AssetImage('images/icons/warning.png'),
                  size: 18,
                  color: purple,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('report_a_problem'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared card ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Route stop row ───────────────────────────────────────────────────────────

// --- Route stop row ---

class _RouteStop extends StatelessWidget {
  final String label;
  final String address;
  const _RouteStop({required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryPurple,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          address,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Detail chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.subtext(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
