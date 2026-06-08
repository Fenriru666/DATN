import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';
import 'package:latlong2/latlong.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  // 1. Mark Driver Online
  Future<void> goOnline(LatLng initialLocation) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.id).set({
      'id': user.id,
      'isOnline': true,
      'isBusy': false,
      'currentLocation': GeoPoint(
        initialLocation.latitude,
        initialLocation.longitude,
      ),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 2. Mark Driver Offline
  Future<void> goOffline() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.id).update({
      'isOnline': false,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Update Real-time GPS Location
  Future<void> updateLocation(LatLng location) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.id).update({
      'currentLocation': GeoPoint(location.latitude, location.longitude),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Listen for New Pending Ride Requests
  Stream<List<OrderModel>> getPendingRideRequests() {
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['Pending', 'Preparing', 'Ready'])
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();

          return orders.where((order) {
            // Filter by serviceType in memory
            if (order.serviceType != 'Ride' && order.serviceType != 'Food') {
              return false;
            }
            if (order.serviceType == 'Ride') {
              return order.status == 'Pending';
            }
            return true;
          }).toList();
        });
  }

  // 5. Accept a Ride Request
  Future<void> acceptRideRequest(String orderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Use transaction to ensure no other driver accepts simultaneously
    String? customerId;

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception("Order does not exist!");
      }

      final status = snapshot.data()?['status'] as String?;
      final serviceType = snapshot.data()?['serviceType'] as String?;

      if (serviceType == 'Ride') {
        if (status != 'Pending') {
          throw Exception("This ride has already been accepted or cancelled.");
        }
      } else {
        if (status != 'Pending' && status != 'Preparing' && status != 'Ready') {
          throw Exception("This order has already been accepted or cancelled.");
        }
      }

      customerId = snapshot.data()?['userId'] as String?;

      transaction.update(docRef, {'status': 'Accepted', 'driverId': user.id});
      final driverRef = _firestore.collection('drivers').doc(user.id);
      transaction.update(driverRef, {'isBusy': true});
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

  // Decline a Ride Request
  Future<void> declineRideRequest(String orderId, {bool isTargeted = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (isTargeted) {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      String? customerId;
      if (doc.exists) {
        customerId = doc.data()?['userId'] as String?;
      }

      await _firestore.collection('orders').doc(orderId).update({
        'driverId': FieldValue.delete(),
        'status': 'Pending',
        'declinedDrivers': FieldValue.arrayUnion([user.id]),
      });

      if (customerId != null) {
        await NotificationSenderService.notifyUser(
          targetUserId: customerId,
          title: "Đang tìm tài xế mới",
          body: "Tài xế đã từ chối chuyến đi. Hệ thống đang tìm kiếm tài xế khác cho bạn.",
        );
      }
    } else {
      await _firestore.collection('orders').doc(orderId).update({
        'declinedDrivers': FieldValue.arrayUnion([user.id]),
      });
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
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.id)
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
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'earningsByDate': <DateTime, double>{}, 'totalRides': 0};
    }

    final snapshot = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.id)
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
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.id)
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

  Future<void> updateBusyStatus(bool isBusy) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.id).update({
      'isBusy': isBusy,
    });
  }

  Future<void> rateCustomer({
    required String orderId,
    required String customerId,
    required double rating,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'customerRating': rating,
    });

    double currentRating = 5.0;
    int currentCount = 0;

    final userDoc = await _firestore.collection('users').doc(customerId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      currentRating = (userData['rating'] ?? 5.0).toDouble();
      currentCount = (userData['ratingCount'] ?? 0) as int;
    }

    final newCount = currentCount + 1;
    final newRating = ((currentRating * currentCount) + rating) / newCount;
    final finalRating = double.parse(newRating.toStringAsFixed(1));

    try {
      await _supabase.from('users').update({
        'rating': finalRating,
        'rating_count': newCount,
      }).eq('id', customerId);
    } catch (_) {}

    try {
      await _firestore.collection('users').doc(customerId).set({
        'rating': finalRating,
        'ratingCount': newCount,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
