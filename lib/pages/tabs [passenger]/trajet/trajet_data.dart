import 'trajet_models.dart';

const List<RideModel> kRides = [
  // ── Upcoming ────────────────────────────────────────────────────
  RideModel(
    vehicleType: 'Premium Sedan',
    vehicleIcon: 'sedan',
    date: 'Today, 18:30',
    vehicleName: 'Toyota Camry',
    price: 42.50,
    pickup: '124 Grand Central Terminal, NY',
    dropoff: 'JFK International Airport, Terminal 4',
    status: RideStatus.upcoming,
  ),
  RideModel(
    vehicleType: 'Economy Plus',
    vehicleIcon: 'economy',
    date: 'Oct 26, 09:15',
    vehicleName: 'Tesla Model 3',
    price: 28.00,
    pickup: '88 Wall Street, Financial District',
    dropoff: 'Times Square 42nd St.',
    status: RideStatus.upcoming,
  ),
   RideModel(
    vehicleType: 'Economy Plus',
    vehicleIcon: 'economy',
    date: 'Oct 26, 09:15',
    vehicleName: 'Tesla Model 3',
    price: 28.00,
    pickup: '88 Wall Street, Financial District',
    dropoff: 'Times Square 42nd St.',
    status: RideStatus.upcoming,
  ),
   RideModel(
    vehicleType: 'Economy Plus',
    vehicleIcon: 'economy',
    date: 'Oct 26, 09:15',
    vehicleName: 'Tesla Model 3',
    price: 28.00,
    pickup: '88 Wall Street, Financial District',
    dropoff: 'Times Square 42nd St.',
    status: RideStatus.upcoming,
  ),

  // ── Completed ────────────────────────────────────────────────────


  // ── Cancelled ─────────────────────────────────────────────────
  RideModel(
    vehicleType: 'Premium Sedan',
    vehicleIcon: 'sedan',
    date: 'Oct 15, 11:00',
    vehicleName: 'BMW 5 Series',
    price: 55.00,
    pickup: 'JFK International Airport',
    dropoff: 'Manhattan Hotel, 5th Ave',
    status: RideStatus.cancelled,
  ),
];