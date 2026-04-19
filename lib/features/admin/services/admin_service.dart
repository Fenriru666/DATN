import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream all users, optionally filtered by role
  Stream<List<UserModel>> streamUsers({UserRole? filterRole}) {
    var stream = _supabase.from('users').stream(primaryKey: ['id']).limit(200);
    
    return stream.map((data) {
      var users = data.map((doc) => UserModel.fromMap(doc, doc['id'])).toList();
      if (filterRole != null) {
        users = users.where((u) => u.roles.contains(filterRole)).toList();
      }
      return users;
    });
  }

  // Stream active partners specifically to avoid client-side filtering large datasets where possible
  Stream<List<UserModel>> streamActivePartners() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('is_approved', true)
        .order('created_at', ascending: false)
        .limit(100) // Fix memory leak and lag by limiting fetching before mapping
        .map((data) {
      // Limit processing and filter roles locally to ensure compatibility with Supabase realtime filters
      final users = data.map((doc) => UserModel.fromMap(doc, doc['id'])).toList();
      return users
          .where((u) => u.roles.contains(UserRole.driver) || u.roles.contains(UserRole.merchant))
          .take(20) // Limit to 20 for performance
          .toList();
    });
  }

  // Get specific users pending approval
  Stream<List<UserModel>> streamPendingUsers() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('is_approved', false)
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) {
      return data.map((doc) => UserModel.fromMap(doc, doc['id'])).toList();
    });
  }

  // Approve a user
  Future<void> approveUser(String uid) async {
    await _supabase.from('users').update({'is_approved': true}).eq('id', uid);
  }

  // Ban or Suspend a user
  Future<void> banUser(String uid) async {
    await _supabase.from('users').update({'is_approved': false}).eq('id', uid);
  }

  // Clean up database: Keep only 50 users and 500 orders
  Future<void> keepOnly50Users() async {
    final response = await _supabase.from('users').select('id, role').order('created_at', ascending: true);
    
    if (response.length > 50) {
      final toDelete = response.skip(50).map((row) => row['id'].toString()).toList();
      for (int i = 0; i < toDelete.length; i += 100) {
        final chunk = toDelete.skip(i).take(100).toList();
        await _supabase.from('users').delete().inFilter('id', chunk);
      }
    }

    // Also clean up orders to prevent database bloat
    final ordersResponse = await _supabase.from('orders').select('id').order('created_at', ascending: false);
    if (ordersResponse.length > 500) {
      final ordersToDelete = ordersResponse.skip(500).map((row) => row['id'].toString()).toList();
      for (int i = 0; i < ordersToDelete.length; i += 100) {
        final chunk = ordersToDelete.skip(i).take(100).toList();
        await _supabase.from('orders').delete().inFilter('id', chunk);
      }
    }
  }

  // Helper for System Stats
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      int totalUsers = 0;
      int totalOrders = 0;
      double totalRevenue = 0.0;
      int custCount = 0;
      int driverCount = 0;
      int merchantCount = 0;

      // Process sequentially to prevent exhausting the Supabase HTTP connection pool
      totalUsers = await _supabase.from('users').count(CountOption.exact);
      custCount = await _supabase.from('users').count(CountOption.exact).eq('role', 'customer');
      driverCount = await _supabase.from('users').count(CountOption.exact).eq('role', 'driver');
      merchantCount = await _supabase.from('users').count(CountOption.exact).eq('role', 'merchant');
      totalOrders = await _supabase.from('orders').count(CountOption.exact).eq('status', 'Completed');
      
      final orders = await _supabase.from('orders')
          .select('total_price, created_at')
          .eq('status', 'Completed')
          .order('created_at', ascending: false)
          .limit(2000);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
          
      List<double> weeklyRevenue = List.filled(7, 0.0);
      double maxDailyOption = 100000.0;

      for (var order in orders) {
        final price = double.tryParse(order['total_price']?.toString() ?? '0') ?? 0.0;
        totalRevenue += price;

        final createdAtStr = order['created_at'];
        if (createdAtStr != null) {
          DateTime createdAt = DateTime.tryParse(createdAtStr) ?? todayStart;
          final diffDays = todayStart.difference(DateTime(createdAt.year, createdAt.month, createdAt.day)).inDays;
          
          if (diffDays >= 0 && diffDays < 7) {
            final index = 6 - diffDays;
            weeklyRevenue[index] += price;
            if (weeklyRevenue[index] > maxDailyOption) {
              maxDailyOption = weeklyRevenue[index];
            }
          }
        }
      }

      final platformRevenue = totalRevenue * 0.15;

      return {
        'totalUsers': totalUsers,
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'platformRevenue': platformRevenue,
        'userDemographics': {
          'customer': custCount,
          'driver': driverCount,
          'merchant': merchantCount,
        },
        'weeklyRevenue': weeklyRevenue,
        'maxDailyRevenue': maxDailyOption,
      };
    } catch (e, st) {
      debugPrint("Error fetching Supabase system stats: $e\\n$st");
      rethrow;
    }
  }
}
