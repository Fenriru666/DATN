import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';
import 'package:datn/core/utils/tier_calculator.dart';
import 'package:datn/core/services/notification_service.dart';
import 'package:datn/features/customer/services/wallet_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final WalletService _walletService = WalletService();

  // Stream for Ongoing Orders (Pending, On the way, etc.)
  Stream<List<OrderModel>> getOngoingOrders() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.id)
        .where('status', whereNotIn: ['Delivered', 'Cancelled', 'Completed'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Stream for Order History (Delivered, Cancelled, Completed)
  Stream<List<OrderModel>> getOrderHistory() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.id)
        .where('status', whereIn: ['Delivered', 'Cancelled', 'Completed'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Keep for backward compatibility or simple view if needed, but prefer the above
  Stream<List<OrderModel>> getRecentOrders() => getOngoingOrders();

  Stream<OrderModel?> getLatestOrder() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.id)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return OrderModel.fromMap(
              snapshot.docs.first.data(),
              snapshot.docs.first.id,
            );
          }
          return null;
        });
  }

  // Stream a specific Order for Real-time tracking
  Stream<OrderModel?> streamOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return OrderModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancellationReason,
  }) async {
    // 1. Get the order to see who needs to be notified
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;

    final data = orderDoc.data()!;
    final userId = data['userId'] as String?;
    final driverId = data['driverId'] as String?;
    final merchantId = data['merchantId'] as String?;

    // 2. Update status & reason
    final updateData = {'status': newStatus};
    if (cancellationReason != null) {
      updateData['cancellationReason'] = cancellationReason;
    }

    await _firestore.collection('orders').doc(orderId).update(updateData);

    // 3. Send Notification based on context
    // If it's Completed or Delivered, it means the Driver or Merchant finished it -> Notify User
    if (newStatus == 'Completed' || newStatus == 'Delivered') {
      // Notify User via Push Notification
      if (userId != null) {
        await NotificationSenderService.notifyUser(
          targetUserId: userId,
          title: "Hoàn thành đơn hàng",
          body:
              "Đơn hàng của bạn đã hoàn thành. Cảm ơn vì đã sử dụng dịch vụ!",
        );
      }

      // Increment completedRides, earn loyalty points, and update tier for Customer
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final currentRides = (userDoc.data()?['completedRides'] ?? 0) as int;
          final newRides = currentRides + 1;
          final currentTier = userDoc.data()?['tier'] ?? 'Bronze';
          final newTier = TierCalculator.calculateTier(newRides);

          final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
          final earnedPoints = (totalPrice * 0.05).toInt();
          final currentPoints = (userDoc.data()?['loyaltyPoints'] ?? 0) as int;
          final newPoints = currentPoints + earnedPoints;

          await _firestore.collection('users').doc(userId).update({
            'completedRides': newRides,
            'loyaltyPoints': newPoints,
            'tier': newTier,
          });

          // In-App Notification: Earned Points
          if (earnedPoints > 0) {
            await NotificationService().sendInAppNotification(
              userId: userId,
              title: "Tích điểm thành công!",
              body:
                  "Bạn vừa nhận được +$earnedPoints Điểm Thưởng từ chuyến đi/đơn hàng. Tích lÅ©y để đổi quà nhé!",
              type: "promo",
              relatedId: orderId,
            );
          }

          // In-App Notification: Tier Upgrade
          if (newTier != currentTier) {
            await NotificationService().sendInAppNotification(
              userId: userId,
              title: "Chúc mừng Thăng Hạng! ðŸŽ‰",
              body:
                  "Wow! Hạng thành viên của bạn đã vươn lên mốc $newTier. Khám phá các ưu đãi đặc quyền mới ngay!",
              type: "system",
            );
          }
        }
      }

      // Increment completedRides and update tier for Driver/Merchant
      final targetServiceProviderId = driverId ?? merchantId;
      if (targetServiceProviderId != null) {
        final providerDoc = await _firestore
            .collection('users')
            .doc(targetServiceProviderId)
            .get();
        if (providerDoc.exists) {
          final currentRides =
              (providerDoc.data()?['completedRides'] ?? 0) as int;
          final newRides = currentRides + 1;
          final newTier = TierCalculator.calculateTier(newRides);

          await _firestore
              .collection('users')
              .doc(targetServiceProviderId)
              .update({'completedRides': newRides, 'tier': newTier});
        }
      }
    }
    // If it's Cancelled, someone aborted -> Notify the other parties
    else if (newStatus == 'Cancelled') {
      final reasonText = cancellationReason != null
          ? "Lý do: $cancellationReason"
          : "Hệ thống tự động hủy.";

      if (driverId != null) {
        await NotificationSenderService.notifyUser(
          targetUserId: driverId,
          title: "Đơn hàng đã bị hủy",
          body: "Khách hàng đã hủy chuyến xe này. $reasonText",
        );
      }
      if (merchantId != null) {
        await NotificationSenderService.notifyUser(
          targetUserId: merchantId,
          title: "Đơn hàng bị khách hủy",
          body: "Khách hàng đã hủy đơn thức ăn này. $reasonText",
        );
      }
      if (userId != null) {
        // Trường hợp tài xế/nhà hàng hủy đơn
        await NotificationSenderService.notifyUser(
          targetUserId: userId,
          title: "Đơn hàng đã bị hủy",
          body: "Rất tiếc, đơn hàng của bạn đã bị hủy. $reasonText",
        );
      }
    }
  }

  Future<void> updateOrderReview(
    String orderId,
    num rating,
    String note,
  ) async {
    // 1. Update order document
    await _firestore.collection('orders').doc(orderId).update({
      'rating': rating,
      'reviewNote': note,
    });

    // 2. Fetch order to get the target driver or merchant
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;

    final data = orderDoc.data()!;
    final driverId = data['driverId'] as String?;
    final merchantId = data['merchantId'] as String?;

    // The target is usually the provider of the service
    final targetId = driverId ?? merchantId;
    if (targetId == null) return;

    // 3. Fetch user (Driver/Merchant) to update their total rating
    final userDoc = await _firestore.collection('users').doc(targetId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentRating = (userData['rating'] ?? 5.0).toDouble();
    final currentCount = (userData['ratingCount'] ?? 0) as int;

    // 4. Calculate new average rating
    // Formula: ((oldAvg * oldCount) + newRating) / (oldCount + 1)
    final newCount = currentCount + 1;
    final newRating =
        ((currentRating * currentCount) + rating.toDouble()) / newCount;

    // 5. Save back to the user document
    await _firestore.collection('users').doc(targetId).update({
      'rating': double.parse(newRating.toStringAsFixed(1)), // Keep 1 decimal
      'ratingCount': newCount,
    });
  }

  // Stream a driver's location for Real-time tracking
  Stream<Map<String, double>?> streamDriverLocation(String driverId) {
    return _firestore.collection('users').doc(driverId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('currentLat') && data.containsKey('currentLng')) {
          return {
            'lat': (data['currentLat'] as num).toDouble(),
            'lng': (data['currentLng'] as num).toDouble(),
          };
        }
      }
      return null;
    });
  }

  Future<String> createOrder(OrderModel order) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Deduct loyalty points if used
    if (order.usedPoints != null && order.usedPoints! > 0) {
      final userDoc = await _firestore.collection('users').doc(user.id).get();
      if (userDoc.exists) {
        final currentPoints = (userDoc.data()?['loyaltyPoints'] ?? 0) as int;
        if (currentPoints >= order.usedPoints!) {
          await _firestore.collection('users').doc(user.id).update({
            'loyaltyPoints': FieldValue.increment(-order.usedPoints!),
          });
        } else {
          throw Exception("Không đủ điểm thưởng.");
        }
      }
    }

    // Process Wallet Payment Priority 20
    if (order.paymentMethod == 'My Wallet' || order.paymentMethod == 'Ví của tôi') {
      try {
        final paymentType = order.serviceType == 'Food' ? 'food' : 'ride';
        final description = order.serviceType == 'Food'
            ? 'Thanh toán đơn hàng ${order.merchantName}'
            : 'Thanh toán di chuyển ${order.serviceType}';

        await _walletService.deductBalance(
          order.totalPrice,
          paymentType,
          description,
        );
      } catch (e) {
        throw Exception("Thanh toán ví thất bại: $e");
      }
    }

    // Ensure the order is linked to the current user
    final orderData = order.toMap();
    orderData['userId'] = user.id;
    orderData.remove('id'); // Let Firestore generate ID

    final docRef = await _firestore.collection('orders').add(orderData);
    return docRef.id;
  }
}
