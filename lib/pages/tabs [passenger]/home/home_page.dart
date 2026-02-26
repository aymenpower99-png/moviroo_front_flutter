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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showStickySearch = false;

  // iconBgColor is the only thing that differs between dark/light,
  // so we keep two lists but reference AppColors for the icon tint
  static const _suggestionsData = [
    (icon: Icons.flight_rounded,          label: 'Airport Rides', sub: 'Fast & reliable transfers'),
    (icon: Icons.route_rounded,           label: 'City to City',  sub: 'Long distance comfort'),
    (icon: Icons.directions_car_rounded,  label: 'Daily Rides',   sub: 'Your regular commute'),
    (icon: Icons.business_center_rounded, label: 'Business',      sub: 'Premium class travel'),
  ];

  static const _recent = [
    RecentRideModel(name: 'Grand Central Terminal', address: '89 E 42nd St, New York', time: '2d ago', type: 'City Ride'),
    RecentRideModel(name: 'JFK International Airport', address: 'Queens, NY 11430',   time: 'Fri',    type: 'Airport'),
    RecentRideModel(name: 'Central Park West',         address: 'New York, NY 10024', time: 'Mon',    type: 'Daily'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 90;
      if (show != _showStickySearch) setState(() => _showStickySearch = show);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build suggestion models here so they can use AppColors
    final suggestions = _suggestionsData.map((d) => SuggestionModel(
      icon:      d.icon,
      label:     d.label,
      sub:       d.sub,
      color:     AppColors.iconBg(context),
      iconColor: AppColors.primaryPurple,
    )).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(showSearch: _showStickySearch),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Greeting
                    Text(
                      'GOOD EVENING',
                      style: AppTextStyles.sectionLabel(context).copyWith(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where to, Alex?',
                      style: AppTextStyles.pageTitle(context).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Visibility(
                      visible: !_showStickySearch,
                      maintainState: false,
                      child: const HomeSearchBar(),
                    ),

                    const SizedBox(height: 30),

                    Text('SUGGESTIONS', style: AppTextStyles.sectionLabel(context)),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: suggestions.map((s) => SuggestionCard(s: s)).toList(),
                    ),

                    const SizedBox(height: 30),
                    const PromoBanner(),
                    const SizedBox(height: 30),

                    Text('RECENT RIDES', style: AppTextStyles.sectionLabel(context)),
                    const SizedBox(height: 14),
                    ..._recent.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RecentRideCard(r: r),
                      ),
                    ),

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