import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../models/vehicle_pricing_response.dart';

class TripSummaryCard extends StatelessWidget {
  final VehicleClassPrice? selectedVehicle;
  final String? pickupAddress;
  final String? dropoffAddress;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  const TripSummaryCard({
    super.key,
    this.selectedVehicle,
    this.pickupAddress,
    this.dropoffAddress,
    this.scheduledDate,
    this.scheduledTime,
  });

  String _formatDistance() {
    final distance = selectedVehicle?.distanceKm ?? 0;
    return '${distance.toStringAsFixed(1)} km';
  }

  String _formatDuration() {
    final duration = selectedVehicle?.durationMin ?? 0;
    return '$duration min';
  }

  String _formatDateTime() {
    if (scheduledDate == null && scheduledTime == null) {
      return 'Now';
    }
    final date = scheduledDate != null
        ? '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year}'
        : '';
    final time = scheduledTime != null
        ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
        : '';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Summary',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          _TripInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Pickup',
            value: pickupAddress ?? 'Pickup location',
          ),
          const SizedBox(height: 12),
          _TripInfoRow(
            icon: Icons.flag_outlined,
            label: 'Dropoff',
            value: dropoffAddress ?? 'Dropoff location',
          ),
          const SizedBox(height: 12),
          _TripInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date & Time',
            value: _formatDateTime(),
          ),
          const SizedBox(height: 12),
          _TripInfoRow(
            icon: Icons.straighten_outlined,
            label: 'Distance',
            value: _formatDistance(),
          ),
          const SizedBox(height: 12),
          _TripInfoRow(
            icon: Icons.access_time_outlined,
            label: 'ETA',
            value: _formatDuration(),
          ),
          const SizedBox(height: 12),
          _TripInfoRow(
            icon: Icons.directions_car_outlined,
            label: 'Vehicle',
            value: selectedVehicle?.name ?? 'Economy',
          ),
          const SizedBox(height: 12),
          _TripInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Passengers',
            value: '${selectedVehicle?.seats ?? 2}',
          ),
        ],
      ),
    );
  }
}

class _TripInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.subtext(context),
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
