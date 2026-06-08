import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class MerchantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  // Stream for Incoming & Active Orders for this Merchant
  Stream<List<OrderModel>> getIncomingOrders() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('merchantId', isEqualTo: user.id)
        .where('status', whereIn: ['Pending', 'Preparing', 'Ready', 'Accepted', 'Arrived', 'InProgress'])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
          // Sort in memory to avoid needing a Firestore composite index!
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  // Stream for History Orders (Completed/Cancelled)
  Stream<List<OrderModel>> getHistoryOrders() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('merchantId', isEqualTo: user.id)
        .where('status', whereIn: ['Completed', 'Cancelled'])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
          // Sort in memory to avoid needing a Firestore composite index!
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Update Order Status (e.g., Pending -> Preparing -> Ready)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // 1. Get the order to find out the userId (Customer)
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;
    final userId = orderDoc.data()?['userId'] as String?;

    // 2. Update status
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });

    if (newStatus == 'Preparing') {
      final merchantId = orderDoc.data()?['merchantId'] as String?;
      _findDeliveryDriverForMerchant(orderId, merchantId);
    }

    // 3. Notify Customer
    if (userId != null) {
      String title = "Cập nhật Đơn hàng";
      String body = "Đơn hàng của bạn đã chuyển sang trạng thái: $newStatus";

      if (newStatus == 'Preparing') {
        body = "Nhà hàng đang chuẩn bị món ăn của bạn!";
      } else if (newStatus == 'Ready') {
        body = "Món ăn đã chuẩn bị xong, chờ tài xế đến lấy nhé!";
      } else if (newStatus == 'Cancelled') {
        body = "Đơn hàng của bạn đã bị nhà hàng từ chối/hủy.";
      }

      await NotificationSenderService.notifyUser(
        targetUserId: userId,
        title: title,
        body: body,
      );
    }
  }

  /// Tìm tài xế online gần cửa hàng nhất để giao đơn đồ ăn khi cửa hàng xác nhận đơn
  Future<void> _findDeliveryDriverForMerchant(String orderId, String? merchantId) async {
    if (merchantId == null || merchantId.isEmpty) return;
    try {
      // 1. Lấy vị trí cửa hàng từ Firestore
      final restDoc = await _firestore.collection('restaurants').doc(merchantId).get();
      if (!restDoc.exists) return;
      final double? restLat = (restDoc.data()?['latitude'] as num?)?.toDouble();
      final double? restLng = (restDoc.data()?['longitude'] as num?)?.toDouble();
      if (restLat == null || restLng == null) return;

      const double searchRadiusKm = 15.0;

      // 2. Lấy tất cả tài xế không bận và đang online từ Firestore
      final snapshot = await _firestore.collection('drivers').get();
      final candidates = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isOnline'] != true) continue;
        if (data['isBusy'] == true) continue;
        final GeoPoint? loc = data['currentLocation'];
        if (loc == null) continue;

        final distKm = Geolocator.distanceBetween(
          restLat,
          restLng,
          loc.latitude,
          loc.longitude,
        ) / 1000;

        if (distKm <= searchRadiusKm) {
          candidates.add({
            'id': data['id'] ?? doc.id,
            'distKm': distKm,
          });
        }
      }

      if (candidates.isEmpty) {
        debugPrint('Không tìm thấy tài xế online nào gần cửa hàng $merchantId');
        return;
      }

      // 3. Chọn tài xế gần nhất
      candidates.sort((a, b) =>
          (a['distKm'] as double).compareTo(b['distKm'] as double));
      final best = candidates.first;
      final driverId = best['id'] as String;

      // 4. Gán driverId vào đơn hàng
      await _firestore.collection('orders').doc(orderId).update({
        'driverId': driverId,
      });

      // 5. Đánh dấu tài xế đang bận
      await _firestore.collection('drivers').doc(driverId).update({
        'isBusy': true,
      });

      // 6. Lấy tên tài xế từ Supabase để hiển thị và gửi thông báo
      try {
        final driverInfo = await _supabase
            .from('users')
            .select('name')
            .eq('id', driverId)
            .maybeSingle();
        final driverName = driverInfo?['name'] ?? 'Tài xế';

        await _firestore.collection('orders').doc(orderId).update({
          'assignedDriverName': driverName,
        });

        // Gửi thông báo cho tài xế
        await NotificationSenderService.notifyUser(
          targetUserId: driverId,
          title: '🍔 Đơn giao hàng mới!',
          body: 'Bạn có đơn giao đồ ăn mới. Đến cửa hàng lấy hàng ngay!',
        );
      } catch (e) {
        debugPrint('Lỗi lấy tên tài xế hoặc thông báo: $e');
      }

      debugPrint('✅ Đã gán tài xế $driverId cho đơn $orderId');
    } catch (e) {
      debugPrint('Lỗi tìm tài xế: $e');
    }
  }

  // Stream menu items for a specific merchant
  Stream<List<Map<String, dynamic>>> streamMenuItems(String merchantId) {
    return _firestore
        .collection('restaurants')
        .doc(merchantId)
        .collection('menu')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Toggle menu item availability
  Future<void> toggleMenuItemAvailability(
    String merchantId,
    String itemId,
    bool isAvailable,
  ) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(merchantId)
          .collection('menu')
          .doc(itemId)
          .update({'isAvailable': isAvailable});
    } catch (e) {
      throw Exception("Cập nhật trạng thái món ăn thất bại");
    }
  }

  // Toggle store online/offline status
  Future<void> toggleStoreStatus(String merchantId, bool isOnline) async {
    try {
      await _firestore.collection('restaurants').doc(merchantId).update({
        'isOnline': isOnline,
      });
    } catch (e) {
      throw Exception("Cập nhật trạng thái cửa hàng thất bại");
    }
  }

  // Add a new menu item
  Future<void> addMenuItem(
    String merchantId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      final docRef = _firestore
          .collection('restaurants')
          .doc(merchantId)
          .collection('menu')
          .doc();
      final newItemData = {
        ...itemData,
        'id': docRef.id, // Ensure the ID matches the document ID
      };
      await docRef.set(newItemData);
    } catch (e) {
      debugPrint('Error adding menu item: $e');
      throw Exception('Failed to add menu item');
    }
  }

  // Update an existing menu item
  Future<void> updateMenuItem(
    String merchantId,
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(merchantId)
          .collection('menu')
          .doc(itemId)
          .update(itemData);
    } catch (e) {
      debugPrint('Error updating menu item: $e');
      throw Exception('Failed to update menu item');
    }
  }

  // Delete a menu item
  Future<void> deleteMenuItem(String merchantId, String itemId) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(merchantId)
          .collection('menu')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      throw Exception('Failed to delete menu item');
    }
  }
}
