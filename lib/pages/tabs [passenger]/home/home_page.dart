import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../widgets/tab_bar.dart';
import 'home_models.dart';
import 'home_header.dart';
import 'home_search_bar.dart';
import 'suggestion_card.dart';
import 'promo_banner.dart';
import 'recent_ride_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import '../../../../services/ride_api/booking_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  // ── User name ──────────────────────────────────────────────────────────────
  final AuthService _authService = AuthService();
  String? _userName;

  // ── Recent rides ───────────────────────────────────────────────────────────
  final BookingApiService _bookingApi = BookingApiService();
  List<RecentRideModel> _recentRides = [];
  bool _isLoadingRides = true;

  static const _suggestionIcons = [
    Icons.flight_rounded,
    Icons.route_rounded,
    Icons.directions_car_rounded,
    Icons.group_rounded,
  ];

  static const _suggestionKeys = [
    'suggestion_airport_label',
    'suggestion_city_label',
    'suggestion_daily_label',
    'suggestion_together_label',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate name from auth cache so the greeting is instantly visible
    // when the user returns to this tab — no flicker or fade delay.
    final cached = _authService.getCachedUser();
    _userName = cached?['firstName'] as String?;

    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUser(),
      _loadRecentRides(),
    ]);
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) return;
      final firstName = user?['firstName'] as String?;
      if (mounted) setState(() => _userName = firstName);
    } catch (_) {
      // Leave existing cached name in place on error
    }
  }

  Future<void> _loadRecentRides() async {
    try {
      final rides = await _bookingApi.getMyRides();
      if (!mounted) return;
      setState(() {
        _recentRides = _mapRides(rides);
        _isLoadingRides = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRides = false);
    }
  }

  List<RecentRideModel> _mapRides(List<Map<String, dynamic>> rides) {
    // Sort by createdAt descending, take latest 5
    final sorted = List<Map<String, dynamic>>.from(rides)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(
          a['createdAt'] ?? a['created_at'] ?? '',
        );
        final bDate = DateTime.tryParse(
          b['createdAt'] ?? b['created_at'] ?? '',
        );
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

    return sorted.take(5).map((r) {
      final createdAt = DateTime.tryParse(
        r['createdAt'] ?? r['created_at'] ?? '',
      );
      final vehicleClass = r['vehicleClass'] as Map<String, dynamic>?;
      final className = vehicleClass?['name'] as String?;

      return RecentRideModel(
        name: r['dropoffAddress'] ?? r['dropoff_address'] ?? 'Unknown',
        address: r['pickupAddress'] ?? r['pickup_address'] ?? '',
        time: createdAt != null ? _formatTimeAgo(createdAt) : '',
        type: className ?? r['status'] ?? 'Ride',
      );
    }).toList();
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 7) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    }
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _greeting(AppLocalizations t) {
    final hour = DateTime.now().hour;
    if (hour < 12) return t.translate('good_morning');
    if (hour < 18) return t.translate('good_afternoon');
    return t.translate('good_evening');
  }

  String _whereToText(AppLocalizations t) {
    final name = _userName;
    if (name != null && name.isNotEmpty) {
      // Strip any trailing ? from the translation so we don't double it
      final whereTo = t.translate('where_to');
      final base = whereTo.endsWith('?')
          ? whereTo.substring(0, whereTo.length - 1).trimRight()
          : whereTo;
      return '$base, $name?';
    }
    return t.translate('where_to');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final suggestions = List.generate(
      _suggestionKeys.length,
      (i) => SuggestionModel(
        icon: _suggestionIcons[i],
        label: t.translate(_suggestionKeys[i]),
        color: AppColors.iconBg(context),
        iconColor: AppColors.primaryPurple,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixed brand header — always visible, never scrolls
            HomeHeader(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Greeting + title — scrolls away normally
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(t),
                            style: AppTextStyles.sectionLabel(context)
                                .copyWith(color: AppColors.primaryPurple),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _whereToText(t),
                            style: AppTextStyles.pageTitle(context).copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),

                  // Search bar — scrolls up, sticks, and shrinks
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SearchBarDelegate(),
                  ),

                  // Rest of content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 30),
                        Text(
                          t.translate('our_services'),
                          style: AppTextStyles.sectionLabel(context),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.75,
                          children: suggestions
                              .map((s) => SuggestionCard(s: s))
                              .toList(),
                        ),
                        const SizedBox(height: 30),
                        const PromoBanner(),
                        const SizedBox(height: 30),
                        Text(
                          t.translate('recent_rides'),
                          style: AppTextStyles.sectionLabel(context),
                        ),
                        const SizedBox(height: 14),

                        // Loading state
                        if (_isLoadingRides)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          )
                        // Empty state
                        else if (_recentRides.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_taxi_outlined,
                                    size: 48,
                                    color: AppColors.subtext(context),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No rides yet',
                                    style: AppTextStyles.bodyLarge(context)
                                        .copyWith(
                                      color: AppColors.subtext(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Book your first ride!',
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                      color: AppColors.subtext(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // Ride list
                        else
                          ..._recentRides.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: RecentRideCard(r: r),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
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

// ─── Delegate ────────────────────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  static const double _maxH = 78.0; // full size (search bar + padding)
  static const double _minH = 56.0; // shrunk size when pinned at top

  @override
  double get maxExtent => _maxH;

  @override
  double get minExtent => _minH;

  @override
  bool shouldRebuild(covariant _SearchBarDelegate old) => false;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // progress: 0.0 = full size scrolling, 1.0 = fully shrunk & pinned
    final progress = (shrinkOffset / (_maxH - _minH)).clamp(0.0, 1.0);

    final barHeight = lerpDouble(60.0, 40.0, progress)!;
    final topPad = lerpDouble(0.0, 8.0, progress)!;
    final bottomPad = lerpDouble(18.0, 8.0, progress)!;
    final borderRadius = lerpDouble(14.0, 10.0, progress)!;
    final showDivider = progress > 0.5;

    return Container(
      color: AppColors.bg(context),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPad, 20, bottomPad),
              child: HomeSearchBar(
                height: barHeight,
                borderRadius: borderRadius,
              ),
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border(context),
            ),
        ],
      ),
    );
  }
}
