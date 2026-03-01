import 'package:flutter/material.dart';

enum SavedPlaceType { home, work, favorite }

extension SavedPlaceTypeExt on SavedPlaceType {
  IconData get icon => switch (this) {
        SavedPlaceType.home     => Icons.home_outlined,
        SavedPlaceType.work     => Icons.work_outline_rounded,
        SavedPlaceType.favorite => Icons.favorite_border_rounded,
      };

  // Key to look up via t() at the call site
  String get defaultLabelKey => switch (this) {
        SavedPlaceType.home     => 'place_home',
        SavedPlaceType.work     => 'place_work',
        SavedPlaceType.favorite => 'place_favourite',
      };
}

class SavedPlace {
  final String id;
  final String label;
  final String address;
  final String city;
  final String province;
  final String zipCode;
  final SavedPlaceType type;

  const SavedPlace({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    required this.province,
    required this.zipCode,
    required this.type,
  });

  SavedPlace copyWith({
    String? label,
    String? address,
    String? city,
    String? province,
    String? zipCode,
    SavedPlaceType? type,
  }) =>
      SavedPlace(
        id: id,
        label: label ?? this.label,
        address: address ?? this.address,
        city: city ?? this.city,
        province: province ?? this.province,
        zipCode: zipCode ?? this.zipCode,
        type: type ?? this.type,
      );

  String get subtitle => [address, city, zipCode]
      .where((s) => s.isNotEmpty)
      .join(', ');
}