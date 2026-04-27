import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import 'trajet_models.dart';
import 'trajet_tab_bar.dart';
import 'ride_card.dart';
import 'pending_ride_card.dart';

class TrajetPage extends StatefulWidget {
  const TrajetPage({super.key});

  @override
  State<TrajetPage> createState() => _TrajetPageState();
}

class _TrajetPageState extends State<TrajetPage> with WidgetsBindingObserver {
  int _tabIndex = 1;
  RideTab _rideTab = RideTab.upcoming;

  final BookingApiService _api = BookingApiService();
  late Future<List<RideModel>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ridesFuture = _loadRides();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<List<RideModel>> _loadRides() async {
    final raw = await _api.getMyRides();
    return raw.map(RideModel.fromJson).toList();
  }

  Future<void> _refresh() async {
    final next = _loadRides();
    setState(() => _ridesFuture = next);
    await next;
  }

  List<RideModel> _filterByTab(List<RideModel> all) {
    switch (_rideTab) {
      case RideTab.upcoming:
        return all
            .where(
              (r) =>
                  r.status == RideStatus.upcoming ||
                  r.status == RideStatus.pendingPayment,
            )
            .toList();
      case RideTab.completed:
        return all.where((r) => r.status == RideStatus.completed).toList();
      case RideTab.cancelled:
        return all.where((r) => r.status == RideStatus.cancelled).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Sticky header + tab bar ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('bookings'),
                    style: AppTextStyles.pageTitle(
                      context,
                    ).copyWith(fontSize: 28, fontWeight: FontWeight.w800),
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

            // ── Ride cards (backed by API) ─────────────────────
            Expanded(
              child: FutureBuilder<List<RideModel>>(
                future: _ridesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }

                  final all = snapshot.data ?? const <RideModel>[];
                  final filtered = _filterByTab(all);

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primaryPurple,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _EmptyState(tab: _rideTab),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final ride = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ride.status == RideStatus.pendingPayment
                              ? PendingRideCard(ride: ride)
                              : RideCard(ride: ride),
                        );
                      },
                    ),
                  );
                },
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

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load rides',
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall(context).copyWith(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
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
      case RideTab.upcoming:
        return 'no_upcoming_rides';
      case RideTab.completed:
        return 'no_completed_rides';
      case RideTab.cancelled:
        return 'no_cancelled_rides';
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
            child: const Icon(
              Icons.directions_car_outlined,
              color: AppColors.primaryPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t(_emptyKey(tab)),
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
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
