import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../../../../../../../theme/app_colors.dart';

class QrView extends StatelessWidget {
  final String? dataUrl;
  const QrView({super.key, required this.dataUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 160,
      height: 160,
      color: AppColors.border(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.qr_code_2_rounded,
        size: 80,
        color: AppColors.subtext(context),
      ),
    );

    if (dataUrl == null) return placeholder;

    final comma = dataUrl!.indexOf(',');
    if (comma < 0) return placeholder;

    try {
      final bytes = base64Decode(dataUrl!.substring(comma + 1));
      return Image.memory(
        bytes,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } catch (_) {
      return placeholder;
    }
  }
}