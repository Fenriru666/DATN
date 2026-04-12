class RideService {
  // Base prices and per km rates based on user request details

  // Bike Rates
  static const double grabBikeBase = 13500;
  static const double grabBikePerKm = 4300;

  static const double beBikeBase = 13200;
  static const double beBikePerKm = 4400;

  static const double xanhSmBikeBase = 13800;
  static const double xanhSmBikePerKm = 4800;

  // Car 4 Seater Rates
  static const double grabCarBase = 29500; // Average of 29-30k
  static const double grabCarPerKm = 10000;

  static const double beCarBase = 31000;
  static const double beCarPerKm = 10750; // Avg of 10.5-11k

  static const double xanhSmCarBase = 30500;
  static const double xanhSmCarPerKm = 14500;

  List<RideOption> calculateRidePrices(double distanceKm) {
    if (distanceKm < 0) distanceKm = 0;

    // First 2km usually included in base, but spec didn't strictly say.
    // Usually these apps have a base fare for first ~2km.
    // I will assume Base satisfies first 2km, then add rate per extra km.
    // OR simpler linear model: Base + (Dist * Rate) if spec implies strict addition.
    // Looking at the prompt: "~13.500đ ~4.300đ". Usually means base fare.
    // Let's assume Base covers first 2km.

    double calc(double base, double rate, double dist) {
      if (dist <= 2) return base;
      return base + ((dist - 2) * rate);
    }

    return [
      // BIKES
      RideOption(
        providerName: "GrabBike",
        type: RideType.bike,
        price: calc(grabBikeBase, grabBikePerKm, distanceKm),
        estimatedTime: _estTime(distanceKm, 30), // 30km/h avg
      ),
      RideOption(
        providerName: "BeBike",
        type: RideType.bike,
        price: calc(beBikeBase, beBikePerKm, distanceKm),
        estimatedTime: _estTime(distanceKm, 30),
      ),
      RideOption(
        providerName: "Xanh SM Bike",
        type: RideType.bike,
        price: calc(xanhSmBikeBase, xanhSmBikePerKm, distanceKm),
        estimatedTime: _estTime(distanceKm, 30),
      ),

      // CARS
      RideOption(
        providerName: "GrabCar",
        type: RideType.car,
        price: calc(grabCarBase, grabCarPerKm, distanceKm),
        estimatedTime: _estTime(distanceKm, 25), // 25km/h avg city
      ),
      RideOption(
        providerName: "BeCar",
        type: RideType.car,
        price: calc(beCarBase, beCarPerKm, distanceKm),
        estimatedTime: _estTime(distanceKm, 25),
      ),
      RideOption(
        providerName: "Xanh SM Car",
        type: RideType.car,
        price: calc(xanhSmCarBase, xanhSmCarPerKm, distanceKm),
        estimatedTime: _estTime(distanceKm, 25),
      ),
    ];
  }

  String _estTime(double dist, double speedKmh) {
    if (dist <= 0) return "1 min";
    double hours = dist / speedKmh;
    int minutes = (hours * 60).ceil();
    return "$minutes min";
  }
}

enum RideType { bike, car }

class RideOption {
  final String providerName;
  final RideType type;
  final double price;
  final String estimatedTime;

  RideOption({
    required this.providerName,
    required this.type,
    required this.price,
    required this.estimatedTime,
  });
}
