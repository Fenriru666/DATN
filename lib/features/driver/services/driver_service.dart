import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';
import 'package:latlong2/latlong.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Mark Driver Online
  Future<void> goOnline(LatLng initialLocation) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.uid).set({
      'id': user.uid,
      'isOnline': true,
      'currentLocation': GeoPoint(
        initialLocation.latitude,
        initialLocation.longitude,
      ),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 2. Mark Driver Offline
  Future<void> goOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.uid).update({
      'isOnline': false,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Update Real-time GPS Location
  Future<void> updateLocation(LatLng location) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.uid).update({
      'currentLocation': GeoPoint(location.latitude, location.longitude),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Listen for New Pending Ride Requests
  Stream<List<OrderModel>> getPendingRideRequests() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Pending')
        .where('serviceType', isEqualTo: 'Ride')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // 5. Accept a Ride Request
  Future<void> acceptRideRequest(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Use transaction to ensure no other driver accepts simultaneously
    String? customerId;

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception("Order does not exist!");
      }

      if (snapshot.data()?['status'] != 'Pending') {
        throw Exception("This ride has already been accepted or cancelled.");
      }

      customerId = snapshot.data()?['userId'] as String?;

      transaction.update(docRef, {'status': 'Accepted', 'driverId': user.uid});
    });

    // Notify Customer
    if (customerId != null) {
      await NotificationSenderService.notifyUser(
        targetUserId: customerId!,
        title: "Kéo rèm thôi, Tài xế đang đến!",
        body: "Đã có tài xế nhận cuốc xe của bạn. Hãy chuẩn bị nhé!",
      );
    }
  }

  // 6. Update Real-time GPS Location on Order for Customer Tracking
  Future<void> updateOrderLocation(String orderId, LatLng location) async {
    await _firestore.collection('orders').doc(orderId).update({
      'driverLat': location.latitude,
      'driverLng': location.longitude,
    });
  }

  // 6.5. Get Active Uncompleted Ride for this Driver
  Future<OrderModel?> getActiveRideOrder() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.uid)
        .where('status', whereIn: ['Accepted', 'Arrived', 'InProgress'])
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return OrderModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  // 7. Get Earnings Summary (Priority 31)
  Future<Map<String, dynamic>> getEarningsSummary(
    DateTime start,
    DateTime end,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'earningsByDate': <DateTime, double>{}, 'totalRides': 0};
    }

    final snapshot = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.uid)
        .where('status', whereIn: ['Completed', 'Delivered'])
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: start.toIso8601String(),
          isLessThanOrEqualTo: end.toIso8601String(),
        )
        .get();

    Map<DateTime, double> earningsByDate = {};
    int totalRides = snapshot.docs.length;

    for (var doc in snapshot.docs) {
      final order = OrderModel.fromMap(doc.data(), doc.id);
      final date = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      earningsByDate[date] = (earningsByDate[date] ?? 0) + order.totalPrice;
    }

    return {'earningsByDate': earningsByDate, 'totalRides': totalRides};
  }

  Stream<List<OrderModel>> getCompletedOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.uid)
        .where('status', whereIn: ['Completed', 'Delivered'])
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
