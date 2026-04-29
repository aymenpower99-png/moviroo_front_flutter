import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

/// Connects the passenger to the live ride WebSocket room.
/// Listens for driver GPS updates and phase-change events.
class PassengerTrackingSocket {
  io.Socket? _socket;

  // ── Callbacks ──────────────────────────────────────────────────────────────
  void Function(double lat, double lng, Map<String, dynamic> data)?
  onLocationUpdate;
  void Function(int? etaMins)? onDriverEnroute;
  void Function()? onDriverArrived;
  void Function()? onRideStarted;
  void Function(Map<String, dynamic> data)? onRideCompleted;

  Future<void> connect(String rideId) async {
    if (_socket != null) {
      debugPrint('🔌 WebSocket already connected');
      return;
    }

    debugPrint('🔌 Connecting to WebSocket for ride: $rideId');
    debugPrint('🔌 WebSocket URL: ${AppConfig.wsBaseUrl}');
    final token = await TokenStorage.getAccess();
    debugPrint('🔌 Token obtained: ${token != null ? "YES" : "NO"}');

    _socket = io.io(
      AppConfig.wsBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({
            if (token != null) 'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          })
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('🔌 WebSocket CONNECTED successfully');
      debugPrint('🔌 Socket ID: ${_socket!.id}');
      debugPrint('🔌 Socket connected: ${_socket!.connected}');
      _socket!.emit('join', {'ride_id': rideId});
      debugPrint('🔌 Joined ride room: $rideId');
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 WebSocket DISCONNECTED');
    });

    _socket!.onConnectError((error) {
      debugPrint('🔌 WebSocket CONNECTION ERROR: $error');
    });

    _socket!.onError((error) {
      debugPrint('🔌 WebSocket ERROR: $error');
    });

    // Log ALL received events for debugging
    _socket!.onAny((event, data) {
      debugPrint('🔌 Received ANY event: $event, data: $data');
    });

    _socket!.on('trip:location_update', (data) {
      debugPrint('🔌 Received trip:location_update: $data');
      if (data is Map) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          onLocationUpdate?.call(lat, lng, Map<String, dynamic>.from(data));
        }
      }
    });

    _socket!.on('trip:enroute', (data) {
      debugPrint('🔌 Received trip:enroute: $data');
      final etaMins = data is Map ? data['driver_eta_min'] as int? : null;
      onDriverEnroute?.call(etaMins);
    });

    _socket!.on('trip:driver_arrived', (_) {
      debugPrint('🔌 Received trip:driver_arrived');
      onDriverArrived?.call();
    });

    _socket!.on('trip:started', (_) {
      debugPrint('🔌 Received trip:started');
      onRideStarted?.call();
    });

    _socket!.on('trip:completed', (data) {
      debugPrint('🔌 Received trip:completed: $data');
      onRideCompleted?.call(data is Map ? Map<String, dynamic>.from(data) : {});
    });
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting WebSocket');
    _socket?.emit('leave', {'ride_id': ''});
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
