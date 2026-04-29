import 'package:flutter/foundation.dart';
import '../../../services/passenger_tracking/passenger_tracking_socket.dart';

/// Service for managing ride connection (WebSocket only - read-only).
class RideConnectionService {
  PassengerTrackingSocket? _socket;

  final String rideId;
  final Function(int?)? onDriverEnroute;
  final Function(double, double, Map<String, dynamic>)? onLocationUpdate;
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
      ..onLocationUpdate = (lat, lng, data) {
        onLocationUpdate?.call(lat, lng, data);
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

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    disconnect();
  }
}
