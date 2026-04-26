import 'package:flutter/material.dart';
import 'package:moviroo/pages/tabs%20%5Bpassenger%5D/trajet/ride_route_column.dart';
import 'package:moviroo/pages/tabs%20%5Bpassenger%5D/trajet/trajet_models.dart';
import '../../../../theme/app_colors.dart';
import '_TripCardHeader.dart';
import '_TripActionButton.dart';

class TripCard extends StatelessWidget {
  final RideModel ride;
  const TripCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TripCardHeader(ride: ride),
            const SizedBox(height: 16),
            RideRouteColumn(ride: ride),
            const SizedBox(height: 16),
            TripActionButton(ride: ride),
          ],
        ),
      ),
    );
  }
}
