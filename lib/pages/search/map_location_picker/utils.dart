/// Check if coordinates are within Tunisia's bounding box
bool isInTunisia(double lat, double lng) {
  return lat >= 30.2 && lat <= 37.5 && lng >= 7.5 && lng <= 11.6;
}
