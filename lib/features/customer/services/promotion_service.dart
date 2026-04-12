import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/promotion_model.dart';
import 'package:datn/core/errors/app_exceptions.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validates and returns a PromotionModel if the code is valid for the given orderValue
  Future<PromotionModel?> validatePromoCode(
    String code,
    double orderValue,
  ) async {
    if (code.trim().isEmpty) return null;

    final standardizedCode = code.trim().toUpperCase();

    final querySnapshot = await _firestore
        .collection('promotions')
        .where('code', isEqualTo: standardizedCode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw ValidationException('Invalid or expired promo code');
    }

    final doc = querySnapshot.docs.first;
    final promotion = PromotionModel.fromMap(doc.data(), doc.id);

    if (promotion.expirationDate.isBefore(DateTime.now())) {
      throw ValidationException('This promo code has expired');
    }

    if (orderValue < promotion.minOrderValue) {
      throw ValidationException(
        'Minimum order value to use this code is ${promotion.minOrderValue.toStringAsFixed(0)}đ',
      );
    }

    return promotion;
  }

  /// Stream active promotions
  Stream<List<PromotionModel>> streamActivePromotions() {
    return _firestore
        .collection('promotions')
        .where('isActive', isEqualTo: true)
        .where('expirationDate', isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Test utility to seed some promo codes
  Future<void> seedPromoCodes() async {
    final batch = _firestore.batch();

    final promos = [
      PromotionModel(
        id: 'promo_1',
        code: 'WELCOME20',
        discountPercentage: 0.2, // 20%
        maxDiscount: 50000,
        minOrderValue: 100000,
        expirationDate: DateTime.now().add(const Duration(days: 30)),
      ),
      PromotionModel(
        id: 'promo_2',
        code: 'FREERIDE',
        discountPercentage: 0.5, // 50%
        maxDiscount: 20000,
        minOrderValue: 0,
        expirationDate: DateTime.now().add(const Duration(days: 7)),
      ),
    ];

    for (var p in promos) {
      final docRef = _firestore.collection('promotions').doc(p.id);
      batch.set(docRef, p.toMap());
    }

    await batch.commit();
  }
}
