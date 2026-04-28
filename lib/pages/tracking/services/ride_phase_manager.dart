import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ride_state.dart';

/// Service for managing ride phase transitions.
class RidePhaseManager {
  RideState advanceToArrived(RideState current, AnimationController pulseAnim) {
    HapticFeedback.mediumImpact();
    pulseAnim.repeat(reverse: true);
    return current.copyWith(phase: RidePhase.driverArrived, progress: 1.0);
  }

  RideState advanceToRideStarted(RideState current) {
    return current.copyWith(phase: RidePhase.rideInProgress, progress: 0.0);
  }

  RideState advanceToRideEnded(RideState current) {
    HapticFeedback.lightImpact();
    return current.copyWith(phase: RidePhase.rideEnded, progress: 1.0);
  }

  String calcArrivalTime(int etaMins) {
    final arrival = DateTime.now().add(Duration(minutes: etaMins));
    return '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';
  }
}
