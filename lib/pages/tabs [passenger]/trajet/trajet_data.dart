import 'trajet_models.dart';

const List<RideModel> kRides = [
  // ── Upcoming ──────────────────────────────────────────────────────
  RideModel(
    vehicleType: 'Premium Sedan',
    vehicleIcon: 'sedan',
    date: '15 Mar 2026',
    time: '18:30',
    vehicleName: 'Toyota Camry',
    price: 42.50,
    pickup: '124 Grand Central Terminal, NY',
    dropoff: 'JFK International Airport, Terminal 4',
    status: RideStatus.upcoming,
    rideId:       '',
    pickupLat:    36.8189,
    pickupLon:    10.1658,
    dropoffLat:   36.8450,
    dropoffLon:   10.2050,
    driverName:   'Ali Ben Salem',
    vehicleColor: 'White',
    plateNumber:  '123 TUN 4',
    etaMins:      7,
  ),

  // ── Pending Payment ───────────────────────────────────────────────
  RideModel(
    vehicleType: 'Economy Plus',
    vehicleIcon: 'economy',
    date: '26 Oct 2026',
    time: '09:15',
    vehicleName: 'Tesla Model 3',
    price: 28.00,
    pickup: '88 Wall Street, Financial District',
    dropoff: 'Times Square 42nd St.',
    status: RideStatus.pendingPayment,
  ),

  // ── Completed ─────────────────────────────────────────────────────
  RideModel(
    vehicleType: 'Economy Plus',
    vehicleIcon: 'economy',
    date: '10 Feb 2026',
    time: '14:00',
    vehicleName: 'Honda Civic',
    price: 22.00,
    pickup: 'Times Square 42nd St.',
    dropoff: 'Brooklyn Bridge, NY',
    status: RideStatus.completed,
  ),

  // ── Cancelled ─────────────────────────────────────────────────────
  RideModel(
    vehicleType: 'Premium Sedan',
    vehicleIcon: 'sedan',
    date: '15 Oct 2026',
    time: '11:00',
    vehicleName: 'BMW 5 Series',
    price: 55.00,
    pickup: 'JFK International Airport',
    dropoff: 'Manhattan Hotel, 5th Ave',
    status: RideStatus.cancelled,
  ),
];