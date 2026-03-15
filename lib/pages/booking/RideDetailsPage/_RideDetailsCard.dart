import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class RideDetailsCard extends StatelessWidget {
  const RideDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RIDE DETAILS',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            )),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.straighten_outlined,
                label: 'Distance',
                value: '142 km',
              ),
              Divider(height: 24, color: AppColors.border(context)),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Duration',
                value: '~1h 30min',
              ),
              Divider(height: 24, color: AppColors.border(context)),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Passengers',
                value: '4',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label,
            style: AppTextStyles.bodyMedium(context)
                .copyWith(color: AppColors.subtext(context))),
        const Spacer(),
        Text(value,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.text(context),
            )),
      ],
    );
  }
}