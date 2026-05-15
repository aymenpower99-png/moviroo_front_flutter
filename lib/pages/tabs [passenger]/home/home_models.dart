import 'package:flutter/material.dart';

class SuggestionModel {
  final IconData icon;
  final String   label;
  final Color    color;
  final Color    iconColor;

  const SuggestionModel({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });
}

class RecentRideModel {
  final String? id;
  final String name;
  final String address;
  final String time;
  final String type;

  const RecentRideModel({
    this.id,
    required this.name,
    required this.address,
    required this.time,
    required this.type,
  });
}