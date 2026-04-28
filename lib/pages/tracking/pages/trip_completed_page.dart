import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/ride_state.dart';
import '../components/trip_summary_card.dart';

/// Full-screen page for trip completion.
/// Shows trip summary and allows user to continue.
class TripCompletedPage extends StatelessWidget {
  final RideState rideState;
  final VoidCallback onContinue;

  const TripCompletedPage({
    super.key,
    required this.rideState,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TripSummaryCard(
              rideState: rideState,
              pickupLabel: rideState.pickupAddress,
              dropLabel: rideState.dropoffAddress,
              onContinue: onContinue,
            ),
          ),
        ),
      ),
    );
  }
}
