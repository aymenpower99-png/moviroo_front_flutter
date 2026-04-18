import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';

/// Connects the passenger to the live ride WebSocket room.
/// Listens for driver GPS updates and phase-change events.
class PassengerTrackingSocket {
  io.Socket? _socket;

  // ── Callbacks ──────────────────────────────────────────────────────────────
  void Function(double lat, double lng)? onLocationUpdate;
  void Function(int? etaMins)? onDriverEnroute;
  void Function()? onDriverArrived;
  void Function()? onRideStarted;
  void Function(Map<String, dynamic> data)? onRideCompleted;

  Future<void> connect(String rideId) async {
    if (_socket != null) return;

    final token = await TokenStorage.getAccess();

    _socket = io.io(
      '${AppConfig.baseUrl}/trips',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders(
            token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join', {'ride_id': rideId});
    });

    _socket!.on('trip:location_update', (data) {
      if (data is Map) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) onLocationUpdate?.call(lat, lng);
      }
    });

    _socket!.on('trip:enroute', (data) {
      final etaMins = data is Map ? data['driver_eta_min'] as int? : null;
      onDriverEnroute?.call(etaMins);
    });

    _socket!.on('trip:driver_arrived', (_) => onDriverArrived?.call());

    _socket!.on('trip:started', (_) => onRideStarted?.call());

    _socket!.on('trip:completed', (data) {
      onRideCompleted?.call(
        data is Map ? Map<String, dynamic>.from(data) : {},
      );
    });
  }

  void disconnect() {
    _socket?.emit('leave', {'ride_id': ''});
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
