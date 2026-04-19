import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';
import 'package:flutter/foundation.dart';

class MerchantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for Incoming & Active Orders for this Merchant
  Stream<List<OrderModel>> getIncomingOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('merchantId', isEqualTo: user.uid)
        .where('status', whereIn: ['Pending', 'Preparing', 'Ready'])
        .orderBy('createdAt', descending: false) // Oldest first to process
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Stream for History Orders (Completed/Cancelled)
  Stream<List<OrderModel>> getHistoryOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('merchantId', isEqualTo: user.uid)
        .where('status', whereIn: ['Completed', 'Cancelled'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
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
