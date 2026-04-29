/// Map configuration constants.
class MapConstants {
  /// Mapbox Access Token
  static const String mapboxAccessToken =
      'pk.eyJ1IjoiYXltb3VuMTEiLCJhIjoiY21vM2JvY3UzMGtrdzJzcXc0cXZwbmE5eiJ9.LcnOY7q-WQ37STLy7wogRA';

  /// Mapbox Style URL
  static const String mapboxStyleUrl = 'mapbox://styles/mapbox/streets-v12';

  /// Default zoom level for map
  static const double defaultZoom = 13.0;

  /// Camera zoom level when following driver
  static const double driverFollowZoom = 15.0;

  /// Camera tilt angle (3D effect)
  static const double cameraTilt = 0.0;

  /// Route line color (purple)
  static const String routeColor = '#A855F7';

  /// Route line width
  static const double routeLineWidth = 4.0;

  /// Route glow line width
  static const double routeGlowWidth = 7.0;

  /// Route glow opacity
  static const double routeGlowOpacity = 0.15;

  /// Route main line opacity
  static const double routeOpacity = 0.85;

  /// Pickup marker color (purple)
  static const String pickupMarkerColor = '#A855F7';

  /// Dropoff marker color (purple)
  static const String dropoffMarkerColor = '#A855F7';

  /// Marker icon size
  static const double markerIconSize = 1.0;

  /// Marker text size
  static const double markerTextSize = 11;

  /// Marker text offset
  static const double markerTextOffset = 2.0;

  /// Driver marker icon size
  static const double driverMarkerIconSize = 1.0;

  /// Driver marker animation duration (milliseconds)
  static const int driverAnimDuration = 1500;

  /// Pulse animation duration (milliseconds)
  static const int pulseAnimDuration = 1000;

  /// ETA refresh throttle (seconds)
  static const int etaRefreshThrottle = 30;

  /// Polling fallback interval (seconds)
  static const int pollingInterval = 10;
}
