import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'trajet_models.dart';
import 'trajet_data.dart';
import 'trajet_tab_bar.dart';
import 'ride_card.dart';
import 'pending_ride_card.dart';

class TrajetPage extends StatefulWidget {
  const TrajetPage({super.key});

  @override
  State<TrajetPage> createState() => _TrajetPageState();
}

class _TrajetPageState extends State<TrajetPage> {
  int _tabIndex    = 1;
  RideTab _rideTab = RideTab.upcoming;

  List<RideModel> get _filtered =>
      kRides.where((r) {
        switch (_rideTab) {
          case RideTab.upcoming:  return r.status == RideStatus.upcoming;
          case RideTab.completed: return r.status == RideStatus.completed;
          case RideTab.cancelled: return r.status == RideStatus.cancelled;
        }
      }).toList();

  bool _isPending(RideModel ride) =>
      ride.status == RideStatus.upcoming && ride.vehicleName == 'Tesla Model 3';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Sticky header + tab bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('bookings'),
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RideTabBar(
                    selected: _rideTab,
                    onTap: (tab) => setState(() => _rideTab = tab),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Scrollable ride cards ────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyState(tab: _rideTab)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _isPending(_filtered[i])
                            ? PendingRideCard(ride: _filtered[i])
                            : RideCard(ride: _filtered[i]),
                      ),
                    ),
            ),

            AppTabBar(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final RideTab tab;
  const _EmptyState({required this.tab});

  String _emptyKey(RideTab tab) {
    switch (tab) {
      case RideTab.upcoming:  return 'no_upcoming_rides';
      case RideTab.completed: return 'no_completed_rides';
      case RideTab.cancelled: return 'no_cancelled_rides';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.iconBg(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_outlined,
                color: AppColors.primaryPurple, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            t(_emptyKey(tab)),
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('no_rides_subtitle'),
            style: AppTextStyles.bodySmall(context).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}