import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Booking number + status ──────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking',
                    style: AppTextStyles.bodySmall(context)
                        .copyWith(color: AppColors.subtext(context))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('#78438620',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w800, fontSize: 22)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            const ClipboardData(text: '78438620'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking ID copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(Icons.copy_outlined,
                          size: 16, color: AppColors.subtext(context)),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded,
                      color: Colors.amber.shade600, size: 13),
                  const SizedBox(width: 5),
                  Text('Payment pending',
                      style: TextStyle(
                        color: Colors.amber.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Route card ───────────────────────────────────────
        Container(
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
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.subtext(context)),
                  const SizedBox(width: 6),
                  Text('13 February 2026, 13:00',
                      style: AppTextStyles.bodySmall(context)),
                ],
              ),
              const SizedBox(height: 16),

              _RouteStop(
                dot: _DotFilled(),
                title: 'Tunis Carthage Airport (TUN)',
                subtitle: 'Tunis, Tunisia',
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 1.5,
                  height: 28,
                  color: AppColors.primaryPurple.withOpacity(0.4),
                ),
              ),
              _RouteStop(
                dot: _DotOutline(),
                title: 'Enfidha Hammamet Airport (NBE)',
                subtitle: 'Enfidha, Tunisia',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteStop extends StatelessWidget {
  final Widget dot;
  final String title;
  final String subtitle;
  const _RouteStop(
      {required this.dot, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 3), child: dot),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.bodyMedium(context)
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.bodySmall(context)),
          ],
        ),
      ],
    );
  }
}

class _DotFilled extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          shape: BoxShape.circle,
        ),
      );
}

class _DotOutline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryPurple, width: 2),
        ),
      );
}