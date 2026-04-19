class TierCalculator {
  static const String bronze = 'Bronze';
  static const String silver = 'Silver';
  static const String gold = 'Gold';
  static const String platinum = 'Platinum';

  /// Returns the appropriate tier based on the number of completed rides
  static String calculateTier(int completedRides) {
    if (completedRides >= 500) {
      return platinum;
    } else if (completedRides >= 100) {
      return gold;
    } else if (completedRides >= 50) {
      return silver;
    } else {
      return bronze;
    }
  }

  /// Optional: Get minimum rides needed for next tier
  static int? getRidesToNextTier(int completedRides) {
    if (completedRides < 50) {
      return 50 - completedRides; // To reach Silver
    } else if (completedRides < 100) {
      return 100 - completedRides; // To reach Gold
    } else if (completedRides < 500) {
      return 500 - completedRides; // To reach Platinum
    }
    return null; // Already Platinum
  }
}
