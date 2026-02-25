import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
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
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Page title ─────────────────────────────────
                    Text(
                      'Rides',
                      style: AppTextStyles.pageTitle(context).copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Tab selector ───────────────────────────────
                    RideTabBar(
                      selected: _rideTab,
                      onTap: (t) => setState(() => _rideTab = t),
                    ),
                    const SizedBox(height: 20),

                    // ── Ride cards ─────────────────────────────────
                    if (_filtered.isEmpty)
                      _EmptyState(tab: _rideTab)
                    else
                      ..._filtered.map((ride) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _isPending(ride)
                                ? PendingRideCard(ride: ride)
                                : RideCard(ride: ride),
                          )),

                    const SizedBox(height: 24),
                  ],
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
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
              'No ${tab.name} rides',
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your ${tab.name} rides will appear here.',
              style: AppTextStyles.bodySmall(context).copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}