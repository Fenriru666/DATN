import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String id;
  final String code;
  final double discountPercentage; // e.g. 0.2 for 20%
  final double maxDiscount;
  final double minOrderValue;
  final DateTime expirationDate;
  final bool isActive;

  PromotionModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.expirationDate,
    this.isActive = true,
  });

  factory PromotionModel.fromMap(Map<String, dynamic> data, String id) {
    return PromotionModel(
      id: id,
      code: data['code'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      maxDiscount: (data['maxDiscount'] ?? 0.0).toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 0.0).toDouble(),
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'discountPercentage': discountPercentage,
      'maxDiscount': maxDiscount,
      'minOrderValue': minOrderValue,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'isActive': isActive,
    };
  }
}
