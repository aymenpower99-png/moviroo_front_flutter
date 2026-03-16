import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class DriverRow extends StatelessWidget {
  const DriverRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.5), width: 2),
            color: const Color(0xFF2A1A4E),
          ),
          child: ClipOval(
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primaryPurple.withOpacity(0.7),
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Name + car
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alexander Wright',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tesla Model S',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),

        // Chat button with custom PNG
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3)),
            ),
            child: Center(
              child: ImageIcon(
                const AssetImage('images/icons/chat.png'),
                size: 20,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
        ),
      ],
    );
  }
}