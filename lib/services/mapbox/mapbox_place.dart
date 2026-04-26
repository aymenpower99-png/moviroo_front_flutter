import 'package:flutter/material.dart';

class MapboxPlace {
  final String id;
  final String placeName;
  final String fullAddress;
  final String city;
  final String country;
  final IconData categoryIcon;
  final double? latitude;
  final double? longitude;

  MapboxPlace({
    required this.id,
    required this.placeName,
    required this.fullAddress,
    required this.categoryIcon,
    this.city = '',
    this.country = '',
    this.latitude,
    this.longitude,
  });

  /// Create from backend geocoding response format
  factory MapboxPlace.fromBackend(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    final displayName = json['display_name'] as String? ?? '';
    final city = json['city'] as String? ?? '';
    final country = json['country'] as String? ?? '';

    // Build full address from components
    final fullAddress = [
      displayName,
      city,
      country,
    ].where((part) => part.isNotEmpty).join(', ');

    // Generate ID from coordinates only (Mapbox-only now)
    final id = 'geo_${lat?.toStringAsFixed(6)}_${lon?.toStringAsFixed(6)}';

    // Determine icon based on display name
    final categoryIcon = _resolveIconFromName(displayName);

    return MapboxPlace(
      id: id,
      placeName: displayName,
      fullAddress: fullAddress,
      city: city,
      country: country,
      categoryIcon: categoryIcon,
      latitude: lat,
      longitude: lon,
    );
  }

  factory MapboxPlace.fromJson(Map<String, dynamic> json) {
    final placeName = json['place_name'] as String? ?? '';
    final fullAddress = json['place_name'] as String? ?? '';
    final center = json['center'] as List?;
    final context = json['context'] as List?;
    final properties = json['properties'] as Map<String, dynamic>?;
    final placeType = json['place_type'] as List?;
    final featureName = json['text'] as String? ?? '';

    final List<String> signals = [];

    if (properties != null) {
      final cat = properties['category'] as String? ?? '';
      if (cat.isNotEmpty) signals.addAll(cat.split(',').map((s) => s.trim()));

      final type = properties['type'] as String? ?? '';
      if (type.isNotEmpty) signals.add(type.trim());

      final maki = properties['maki'] as String? ?? '';
      if (maki.isNotEmpty) signals.add(maki.trim());

      final address = properties['address'] as String? ?? '';
      if (address.isNotEmpty) signals.add(address.toLowerCase());
    }

    if (placeType != null) {
      for (final t in placeType) {
        if (t is String && t.isNotEmpty) signals.add(t.trim());
      }
    }

    if (context != null) {
      for (final item in context) {
        if (item is Map<String, dynamic>) {
          final ctxId = item['id'] as String? ?? '';
          if (ctxId.startsWith('category.')) {
            signals.add(ctxId.replaceFirst('category.', '').trim());
          }
          final ctxText = item['text'] as String? ?? '';
          if (ctxText.isNotEmpty) signals.add(ctxText.toLowerCase());
        }
      }
    }

    signals.add(featureName.toLowerCase());
    signals.add(placeName.toLowerCase());

    return MapboxPlace(
      id: json['id'] as String? ?? '',
      placeName: placeName,
      fullAddress: fullAddress,
      categoryIcon: _resolveIcon(signals),
      latitude: center != null && center.length >= 2
          ? (center[1] as num).toDouble()
          : null,
      longitude: center != null && center.length >= 2
          ? (center[0] as num).toDouble()
          : null,
    );
  }

  static IconData _resolveIcon(List<String> signals) {
    final combined = signals.join(' ').toLowerCase();

    if (_has(combined, [
      'airport',
      'aéroport',
      'aeroport',
      'aerodrome',
      'carthage international',
      'tunis-carthage',
      'enfidha',
      'monastir habib',
      'djerba-zarzis',
      'sfax-thyna',
      'tabarka',
    ])) {
      return Icons.flight;
    }
    if (_has(combined, [
      'hotel',
      'hôtel',
      'lodging',
      'motel',
      'hostel',
      'guesthouse',
      'guest_house',
      'riad',
      'resort',
      'auberge',
      'dar ',
      'pension',
      'villa ',
    ])) {
      return Icons.hotel;
    }
    if (_has(combined, [
      'restaurant',
      'eatery',
      'diner',
      'brasserie',
      'rotisserie',
      'grill',
    ])) {
      return Icons.restaurant;
    }
    if (_has(combined, ['cafe', 'café', 'coffee', 'tearoom', 'salon de thé'])) {
      return Icons.coffee;
    }
    if (_has(combined, [
      'bakery',
      'boulangerie',
      'pastry',
      'patisserie',
      'pâtisserie',
    ])) {
      return Icons.bakery_dining;
    }
    if (_has(combined, ['bar', 'pub', 'nightclub', 'lounge'])) {
      return Icons.local_bar;
    }
    if (_has(combined, [
      'fast_food',
      'fastfood',
      'fast food',
      'burger',
      'sandwich',
      'pizza',
    ])) {
      return Icons.fastfood;
    }
    if (_has(combined, ['ice_cream', 'icecream', 'ice cream', 'glace'])) {
      return Icons.icecream;
    }
    if (_has(combined, ['train', 'station', 'gare', 'railway'])) {
      return Icons.train;
    }
    if (_has(combined, ['metro', 'subway'])) return Icons.subway;
    if (_has(combined, ['bus', 'autobus', 'gare routière', 'gare routiere'])) {
      return Icons.directions_bus;
    }
    if (_has(combined, ['taxi', 'louage'])) return Icons.local_taxi;
    if (_has(combined, [
      'fuel',
      'gas_station',
      'petrol',
      'station-service',
      'essence',
    ])) {
      return Icons.local_gas_station;
    }
    if (_has(combined, ['parking'])) return Icons.local_parking;
    if (_has(combined, ['port', 'marina', 'harbour', 'harbor'])) {
      return Icons.directions_boat;
    }
    if (_has(combined, [
      'hospital',
      'clinic',
      'clinique',
      'medical',
      'doctor',
      'médecin',
      'hopital',
      'hôpital',
      'polyclinique',
    ])) {
      return Icons.local_hospital;
    }
    if (_has(combined, ['pharmacy', 'pharmacie', 'drugstore'])) {
      return Icons.medication;
    }
    if (_has(combined, [
      'school',
      'école',
      'university',
      'université',
      'college',
      'collège',
      'lycée',
      'lycee',
      'kindergarten',
      'maternelle',
      'institut',
    ])) {
      return Icons.school;
    }
    if (_has(combined, ['library', 'bibliothèque', 'bibliotheque'])) {
      return Icons.local_library;
    }
    if (_has(combined, ['mall', 'centre commercial', 'shopping'])) {
      return Icons.shopping_bag;
    }
    if (_has(combined, [
      'supermarket',
      'supermarché',
      'supermarche',
      'grocery',
      'épicerie',
      'epicerie',
      'marché',
      'marche',
      'market',
    ])) {
      return Icons.shopping_cart;
    }
    if (_has(combined, ['shop', 'store', 'boutique', 'magasin'])) {
      return Icons.storefront;
    }
    if (_has(combined, ['cinema', 'movie', 'film'])) return Icons.movie;
    if (_has(combined, ['theater', 'theatre', 'théâtre'])) {
      return Icons.theater_comedy;
    }
    if (_has(combined, ['museum', 'musée', 'musee', 'gallery', 'galerie'])) {
      return Icons.museum;
    }
    if (_has(combined, ['stadium', 'stade', 'arena'])) return Icons.stadium;
    if (_has(combined, ['attraction', 'amusement', 'theme park'])) {
      return Icons.attractions;
    }
    if (_has(combined, ['zoo'])) return Icons.pets;
    if (_has(combined, ['aquarium'])) return Icons.water;
    if (_has(combined, ['bank', 'banque', 'atm', 'guichet'])) {
      return Icons.account_balance;
    }
    if (_has(combined, ['post_office', 'poste', 'la poste'])) {
      return Icons.local_post_office;
    }
    if (_has(combined, ['police', 'commissariat', 'gendarmerie'])) {
      return Icons.local_police;
    }
    if (_has(combined, ['fire_station', 'pompiers'])) {
      return Icons.local_fire_department;
    }
    if (_has(combined, [
      'embassy',
      'ambassade',
      'consulat',
      'consulate',
      'government',
      'gouvernement',
      'municipalité',
      'municipalite',
      'mairie',
    ])) {
      return Icons.account_balance;
    }
    if (_has(combined, ['beach', 'plage'])) return Icons.beach_access;
    if (_has(combined, ['park', 'parc', 'jardin', 'garden'])) return Icons.park;
    if (_has(combined, ['camping', 'campground'])) return Icons.terrain;
    if (_has(combined, ['hiking', 'randonnée', 'randonnee'])) {
      return Icons.hiking;
    }
    if (_has(combined, ['golf'])) return Icons.sports_golf;
    if (_has(combined, ['gym', 'fitness', 'salle de sport'])) {
      return Icons.fitness_center;
    }
    if (_has(combined, ['spa', 'hammam', 'thalasso'])) return Icons.spa;
    if (_has(combined, ['sport'])) return Icons.sports;
    if (_has(combined, ['mosque', 'mosquée', 'mosquee', 'masjid'])) {
      return Icons.mosque;
    }
    if (_has(combined, [
      'church',
      'église',
      'eglise',
      'cathedral',
      'cathédrale',
    ])) {
      return Icons.church;
    }
    if (_has(combined, ['synagogue'])) return Icons.synagogue;
    if (_has(combined, ['temple', 'shrine'])) return Icons.temple_buddhist;

    return Icons.location_on;
  }

  static bool _has(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  /// Resolve icon from display name (for backend responses)
  static IconData _resolveIconFromName(String name) {
    final lowerName = name.toLowerCase();
    return _resolveIcon([lowerName]);
  }
}
