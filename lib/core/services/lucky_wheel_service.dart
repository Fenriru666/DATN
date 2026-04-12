import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/user_model.dart';
import 'dart:math';

class LuckyWheelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Wheel Items
  static const List<Map<String, dynamic>> wheelItems = [
    {"label": "Chúc may mắn", "type": "NONE", "value": 0, "color": 0xFF9E9E9E}, // Grey
    {"label": "1.000đ", "type": "WALLET", "value": 1000, "color": 0xFFFE724C}, // Orange
    {"label": "5.000đ", "type": "WALLET", "value": 5000, "color": 0xFF4CAF50}, // Green
    {"label": "Chúc may mắn", "type": "NONE", "value": 0, "color": 0xFF9E9E9E}, // Grey
    {"label": "10.000đ", "type": "WALLET", "value": 10000, "color": 0xFFFFC107}, // Amber
    {"label": "2.000đ", "type": "WALLET", "value": 2000, "color": 0xFF2196F3}, // Blue
  ];

  static const int pointsPerSpin = 50;

  Future<int> spinWheel(String userId) async {
    final userDocRef = _firestore.collection('users').doc(userId);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) {
        throw Exception("User not found");
      }

      final userModel = UserModel.fromMap(snapshot.data()!, snapshot.id);

      if (userModel.loyaltyPoints < pointsPerSpin) {
        throw Exception("Không đủ Điểm Thành viên (Cần $pointsPerSpin điểm)");
      }

      // 1. Deduct Points
      transaction.update(userDocRef, {
        'loyaltyPoints': FieldValue.increment(-pointsPerSpin),
      });

      // 2. Determine prize index based on rigged probabilities
      // 40% none, 30% 1k, 15% 2k, 10% 5k, 5% 10k
      final random = Random();
      final prob = random.nextInt(100);
      int selectedIndex = 0;

      if (prob < 40) {
        // None
        selectedIndex = random.nextBool() ? 0 : 3;
      } else if (prob < 70) {
        // 1000
        selectedIndex = 1;
      } else if (prob < 85) {
        // 2000
        selectedIndex = 5;
      } else if (prob < 95) {
        // 5000
        selectedIndex = 2;
      } else {
        // 10000
        selectedIndex = 4;
      }

      final prize = wheelItems[selectedIndex];

      // 3. Apply Reward
      if (prize['type'] == 'WALLET') {
        final amount = prize['value'] as int;
        transaction.update(userDocRef, {
           'walletBalance': FieldValue.increment(amount),
        });

        // Log transaction
        final txRef = _firestore.collection('wallet_transactions').doc();
        transaction.set(txRef, {
          'userId': userId,
          'amount': amount,
          'type': 'LUCKY_WHEEL_PRIZE',
          'description': 'Trúng thưởng Vòng Quay May Mắn',
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Log Wheel Spin History
      final historyRef = _firestore.collection('lucky_wheel_history').doc();
      transaction.set(historyRef, {
        'userId': userId,
        'pointsDeducted': pointsPerSpin,
        'prizeLabel': prize['label'],
        'prizeType': prize['type'],
        'prizeValue': prize['value'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      return selectedIndex;
    });
  }
}
