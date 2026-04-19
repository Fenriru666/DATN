class OrderModel {
  final String id;
  final String userId;
  final String merchantName;
  final String merchantImage; // Color hex or URL
  final String itemsSummary; // e.g., "1x Whopper, 2x Fries"
  final double totalPrice;
  final String status; // 'Delivered', 'On the way', 'Cancelled'
  final DateTime createdAt;
  final String serviceType; // 'Food', 'Mart', 'Ride'
  final String address;

  // New Geospatial Fields for Ride-Hailing & Real-time tracking
  final String? driverId;
  final String? merchantId; // ID of the restaurant/merchant
  final num? pickupLat;
  final num? pickupLng;
  final num? dropoffLat;
  final num? dropoffLng;
  final num? distance;

  // Payment & Review Fields (Priority 4)
  final String? paymentMethod; // 'Cash', 'MoMo', 'ZaloPay', etc.
  final num? rating;
  final String? reviewNote; // distance in km or meters
  final double? driverLat;
  final double? driverLng;
  final String? cancellationReason;

  // Loyalty Points (Priority 17)
  final int? usedPoints;

  // Scheduled Rides (Priority 18)
  final DateTime? scheduledTime;

  OrderModel({
    required this.id,
    required this.userId,
    required this.merchantName,
    required this.merchantImage,
    required this.itemsSummary,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.serviceType,
    required this.address,
    this.driverId,
    this.merchantId,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.distance,
    this.paymentMethod,
    this.rating,
    this.reviewNote,
    this.driverLat,
    this.driverLng,
    this.cancellationReason,
    this.usedPoints,
    this.scheduledTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'merchantName': merchantName,
      'merchantImage': merchantImage,
      'itemsSummary': itemsSummary,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'serviceType': serviceType,
      'address': address,
      'driverId': driverId,
      'merchantId': merchantId,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'distance': distance,
      'paymentMethod': paymentMethod ?? 'Cash', // Default to Cash
      'rating': rating,
      'reviewNote': reviewNote,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'cancellationReason': cancellationReason,
      'usedPoints': usedPoints ?? 0,
      'scheduledTime': scheduledTime?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      merchantName: map['merchantName'] ?? '',
      merchantImage: map['merchantImage'] ?? '',
      itemsSummary: map['itemsSummary'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      serviceType: map['serviceType'] ?? 'Food',
      address: map['address'] ?? '',
      driverId: map['driverId'],
      merchantId: map['merchantId'],
      pickupLat: map['pickupLat'],
      pickupLng: map['pickupLng'],
      dropoffLat: map['dropoffLat'],
      dropoffLng: map['dropoffLng'],
      distance: map['distance'],
      paymentMethod: map['paymentMethod'],
      rating: map['rating'],
      reviewNote: map['reviewNote'],
      driverLat: map['driverLat']?.toDouble(),
      driverLng: map['driverLng']?.toDouble(),
      cancellationReason: map['cancellationReason'],
      usedPoints: map['usedPoints'],
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.parse(map['scheduledTime'])
          : null,
    );
  }
}
