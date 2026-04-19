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
    var rawExp = data['expiration_date'] ?? data['expirationDate'];
    
    return PromotionModel(
      id: id,
      code: data['code'] ?? '',
      discountPercentage: (data['discount_percentage'] ?? data['discountPercentage'] ?? 0.0).toDouble(),
      maxDiscount: (data['max_discount'] ?? data['maxDiscount'] ?? 0.0).toDouble(),
      minOrderValue: (data['min_order_value'] ?? data['minOrderValue'] ?? 0.0).toDouble(),
      expirationDate: rawExp != null
          ? (DateTime.tryParse(rawExp.toString()) ?? DateTime.now())
          : DateTime.now(),
      isActive: data['is_active'] ?? data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'discount_percentage': discountPercentage,
      'max_discount': maxDiscount,
      'min_order_value': minOrderValue,
      'expiration_date': expirationDate.toIso8601String(),
      'is_active': isActive,
    };
  }
}
