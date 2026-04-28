import 'dart:async';
import 'package:flutter/services.dart';
import '../../../services/passenger_tracking/passenger_tracking_socket.dart';
import '../../../services/ride_api/ride_api_service.dart';
import '../models/ride_state.dart';

/// Service for managing ride connection (WebSocket + polling fallback).
class RideConnectionService {
  PassengerTrackingSocket? _socket;
  Timer? _pollTimer;

  final String rideId;
  final Function(int?)? onDriverEnroute;
  final Function(double, double)? onLocationUpdate;
  final VoidCallback? onDriverArrived;
  final VoidCallback? onRideStarted;
  final Function(Map<String, dynamic>)? onRideCompleted;

  RideConnectionService({
    required this.rideId,
    this.onDriverEnroute,
    this.onLocationUpdate,
    this.onDriverArrived,
    this.onRideStarted,
    this.onRideCompleted,
  });

  void connect() {
    _socket = PassengerTrackingSocket()
      ..onDriverEnroute = (etaMins) {
        onDriverEnroute?.call(etaMins);
      }
      ..onLocationUpdate = (lat, lng) {
        onLocationUpdate?.call(lat, lng);
      }
      ..onDriverArrived = () {
        onDriverArrived?.call();
      }
      ..onRideStarted = () {
        onRideStarted?.call();
      }
      ..onRideCompleted = (data) {
        onRideCompleted?.call(data);
      };
    _socket!.connect(rideId);
  }

  void startPolling(RideState currentState, Function(RideState) onUpdate) {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _poll(currentState, onUpdate);
    });
  }

  Future<void> _poll(RideState currentState, Function(RideState) onUpdate) async {
    try {
      final rideApiService = RideApiService();
      final response = await rideApiService.getTripStatus(rideId);
      if (response == null) return;

      final status = response['status'] as String?;
      final etaMins = response['etaMins'] as int?;

      switch (status) {
        case 'DRIVER_ON_THE_WAY':
          if (etaMins != null) {
            onUpdate(currentState.copyWith(
              etaMins: etaMins,
              arrivalTime: _calcArrivalTime(etaMins),
            ));
          }
          break;
        case 'DRIVER_ARRIVED':
          if (currentState.phase != RidePhase.driverArrived) {
            onDriverArrived?.call();
          }
          break;
        case 'RIDE_IN_PROGRESS':
          if (currentState.phase != RidePhase.rideInProgress &&
              currentState.phase != RidePhase.rideEnded) {
            onRideStarted?.call();
          }
          break;
        case 'COMPLETED':
          if (currentState.phase != RidePhase.rideEnded) {
            onRideCompleted?.call(response);
          }
          break;
      }
    } catch (e) {
      // Polling errors are tolerated
    }
  }

  String _calcArrivalTime(int etaMins) {
    final arrival = DateTime.now().add(Duration(minutes: etaMins));
    return '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';
  }

  void disconnect() {
    _socket?.disconnect();
    _pollTimer?.cancel();
  }

  void dispose() {
    disconnect();
  }
}
