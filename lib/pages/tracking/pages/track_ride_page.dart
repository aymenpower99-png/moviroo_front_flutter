library track_ride_page;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../theme/app_colors.dart';
import '../../../routing/router.dart';
import '../widgets/ui/bottom_panel.dart';
import '../widgets/overlays/trip_completed_overlay.dart';
import '../models/ride_state.dart';
import '../controllers/tracking_map_controller.dart';
import '../utils/map_constants.dart';
import '../services/ride_data_loader.dart';
import '../services/driver_animation_controller.dart';
import '../services/ride_connection_service.dart';
import '../services/ride_phase_manager.dart';
import '../services/progress_calculator.dart';
import '../../../services/ride_tracking_cache.dart';
import '../widgets/skeleton/tracking_skeleton.dart';

// Part mixins - these share the class definition and imports from this file
part 'track_ride/track_ride_state.dart';
part 'track_ride/track_ride_callbacks.dart';
part 'track_ride/track_ride_lifecycle.dart';
part 'track_ride/track_ride_build.dart';
// ─────────────────────────────────────────────────────────────────────────────
// TrackRidePage
// Main entry point. All logic is delegated to part-file mixins:
//   • _TrackRideStateMixin      — state fields, helpers, backend init
//   • _TrackRideCallbacksMixin  — event/callback handlers
//   • _TrackRideLifecycleMixin  — initState / dispose / parallel init
//   • _TrackRideBuildMixin      — build() and widget helpers
// ─────────────────────────────────────────────────────────────────────────────

class TrackRidePage extends StatefulWidget {
  final String rideId;
  final double? pickupLat;
  final double? pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? driverName;
  final String? driverId;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;
  final int? etaMins;

  const TrackRidePage({
    super.key,
    required this.rideId,
    this.pickupLat,
    this.pickupLon,
    this.dropoffLat,
    this.dropoffLon,
    this.pickupAddress,
    this.dropoffAddress,
    this.driverName,
    this.driverId,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
    this.etaMins,
  });

  @override
  State<TrackRidePage> createState() => _TrackRidePageState();
}

class _TrackRidePageState extends State<TrackRidePage>
    with
        TickerProviderStateMixin,
        _TrackRideStateMixin,
        _TrackRideCallbacksMixin,
        _TrackRideLifecycleMixin,
        _TrackRideBuildMixin {
  @override
  void initState() {
    super.initState();
    initRide();
  }

  @override
  void dispose() {
    disposeRide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildPage(context);
}
