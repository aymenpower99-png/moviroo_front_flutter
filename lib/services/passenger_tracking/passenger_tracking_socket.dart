import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

/// Connects the passenger to the live ride WebSocket room.
/// Listens for driver GPS updates and phase-change events.
///
/// Includes automatic retry with exponential backoff on connection failure.
class PassengerTrackingSocket {
  io.Socket? _socket;

  // ── Retry state ──────────────────────────────────────────────────────────
  static const int _maxRetries = 5;
  int _retryCount = 0;
  Timer? _retryTimer;
  String? _activeRideId;
  bool _disposed = false;

  // ── Callbacks ───────────────────────────────────────────────────────────
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

    _activeRideId = rideId;
    _disposed = false;

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
      _retryCount = 0; // Reset retry counter on success
      _socket!.emit('join', {'ride_id': rideId});
      debugPrint('🔌 Joined ride room: $rideId');
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 WebSocket DISCONNECTED');
      _scheduleRetry();
    });

    _socket!.onConnectError((error) {
      debugPrint('🔌 WebSocket CONNECTION ERROR: $error');
      _scheduleRetry();
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

    // Also listen for trip:gps (driver's event name) for compatibility
    _socket!.on('trip:gps', (data) {
      debugPrint('🔌 Received trip:gps: $data');
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

  void _scheduleRetry() {
    if (_disposed) return;
    if (_retryCount >= _maxRetries) {
      debugPrint('🔌 Max retry attempts ($_maxRetries) reached — giving up.');
      return;
    }
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) return;

    _retryCount++;
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s (capped)
    final delaySeconds = (1 << (_retryCount - 1)).clamp(1, 16);
    debugPrint('🔌 Retry $_retryCount/$_maxRetries in ${delaySeconds}s…');

    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_disposed) return;
      // Tear down old socket and reconnect.
      try {
        _socket?.dispose();
      } catch (_) {}
      _socket = null;
      connect(rideId);
    });
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting WebSocket');
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _socket?.emit('leave', {'ride_id': _activeRideId ?? ''});
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _activeRideId = null;
  }
}
