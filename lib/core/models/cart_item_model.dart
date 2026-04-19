class CartItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image; // Color hex or URL
  final String merchantId;
  final String merchantName;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.merchantId,
    required this.merchantName,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'merchantId': merchantId,
      'merchantName': merchantName,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      image: map['image'] ?? '',
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? '',
    );
  }

  CartItemModel copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? image,
    String? merchantId,
    String? merchantName,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
    );
  }
}
