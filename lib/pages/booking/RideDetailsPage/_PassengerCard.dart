import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class PassengerCard extends StatelessWidget {
  final String? passengerName;
  final String? email;
  final String? phone;

  const PassengerCard({super.key, this.passengerName, this.email, this.phone});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('passenger'),
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.subtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              PassengerRow(
                icon: Icons.person_outline_rounded,
                label: t.translate('main_passenger'),
                value: passengerName ?? 'Aymen Ben Nacer',
                editable: false,
                isFirst: true,
              ),
              Divider(height: 1, color: AppColors.border(context)),
              PassengerRow(
                icon: Icons.email_outlined,
                label: t.translate('email'),
                value: email ?? 'aymenpower99@gmail.com',
                editable: false,
              ),
              Divider(height: 1, color: AppColors.border(context)),
              PassengerRow(
                icon: Icons.phone_outlined,
                label: t.translate('phone_number'),
                value: phone ?? '+21694338510',
                editable: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PassengerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool editable;
  final bool isFirst;

  const PassengerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.editable = false,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: isFirst
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.subtext(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}
