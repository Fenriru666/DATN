import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyModel {
  final String id;
  final String userId;
  final String userRole; // "Customer" or "Driver"
  final String? orderId; // Optional: If they are on a trip
  final double lat;
  final double lng;
  final String status; // "Pending", "Resolved"
  final DateTime timestamp;

  EmergencyModel({
    required this.id,
    required this.userId,
    required this.userRole,
    this.orderId,
    required this.lat,
    required this.lng,
    this.status = 'Pending',
    required this.timestamp,
  });

  factory EmergencyModel.fromMap(Map<String, dynamic> data, String id) {
    return EmergencyModel(
      id: id,
      userId: data['userId'] ?? '',
      userRole: data['userRole'] ?? 'Unknown',
      orderId: data['orderId'],
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
