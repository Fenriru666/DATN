import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream all users, optionally filtered by role
  Stream<List<UserModel>> streamUsers({UserRole? filterRole}) {
    Query query = _firestore.collection('users');

    if (filterRole != null) {
      query = query.where(
        'roles',
        arrayContains: filterRole.toString().split('.').last,
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get specific users pending approval
  Stream<List<UserModel>> streamPendingUsers() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Approve a user
  Future<void> approveUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'isApproved': true});
  }

  // Ban or Suspend a user
  Future<void> banUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'isApproved': false});
  }

  // Helper for System Stats
  Future<Map<String, dynamic>> getSystemStats() async {
    int totalUsers = 0;
    int totalOrders = 0;
    double totalRevenue = 0.0;

    // 1. Count Users
    final usersSnap = await _firestore.collection('users').count().get();
    totalUsers = usersSnap.count ?? 0;

    // 2. Aggregate Orders (Completed ones for revenue)
    final ordersSnap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Completed')
        .get();

    totalOrders = ordersSnap.docs.length;
    for (var doc in ordersSnap.docs) {
      final data = doc.data();
      totalRevenue += (data['totalPrice'] ?? 0.0).toDouble();
    }

    // Assuming a hypothetical 15% platform fee for revenue stat
    final platformRevenue = totalRevenue * 0.15;

    return {
      'totalUsers': totalUsers,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'platformRevenue': platformRevenue,
    };
  }
}
