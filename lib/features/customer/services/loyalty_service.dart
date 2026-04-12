import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tier Thresholds
  static const int silverThreshold = 100;
  static const int goldThreshold = 500;
  static const int platinumThreshold = 1000;

  // Tier Names
  static const String tierBronze = 'Bronze';
  static const String tierSilver = 'Silver';
  static const String tierGold = 'Gold';
  static const String tierPlatinum = 'Platinum';

  /// Calculate tier based on points
  String calculateTier(int points) {
    if (points >= platinumThreshold) return tierPlatinum;
    if (points >= goldThreshold) return tierGold;
    if (points >= silverThreshold) return tierSilver;
    return tierBronze;
  }

  /// Get benefits for a specific tier
  List<String> getBenefits(String tier) {
    switch (tier) {
      case tierPlatinum:
        return [
          '15% Discount on all orders',
          'Free Delivery',
          'Priority Support',
          'Exclusive Deals',
        ];
      case tierGold:
        return [
          '10% Discount on all orders',
          'Priority Support',
          'Exclusive Deals',
        ];
      case tierSilver:
        return ['5% Discount on all orders', 'Exclusive Deals'];
      case tierBronze:
      default:
        return ['Earn points on every order'];
    }
  }

  /// Get next tier and points needed
  Map<String, dynamic> getNextTierInfo(int currentPoints) {
    if (currentPoints >= platinumThreshold) {
      return {'nextTier': null, 'pointsNeeded': 0};
    }
    if (currentPoints >= goldThreshold) {
      return {
        'nextTier': tierPlatinum,
        'pointsNeeded': platinumThreshold - currentPoints,
      };
    }
    if (currentPoints >= silverThreshold) {
      return {
        'nextTier': tierGold,
        'pointsNeeded': goldThreshold - currentPoints,
      };
    }
    return {
      'nextTier': tierSilver,
      'pointsNeeded': silverThreshold - currentPoints,
    };
  }

  /// Add points to user and update tier if necessary
  Future<void> addPoints(String uid, int pointsToAdd) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        int currentPoints = data['loyaltyPoints'] ?? 0;
        int newPoints = currentPoints + pointsToAdd;
        String newTier = calculateTier(newPoints);

        transaction.update(userRef, {
          'loyaltyPoints': newPoints,
          'tier': newTier,
        });
      });
    } catch (e) {
      debugPrint("Error adding points: $e");
      rethrow;
    }
  }
}
