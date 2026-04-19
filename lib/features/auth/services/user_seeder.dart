import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class UserSeeder {
  SupabaseClient get _supabase => Supabase.instance.client;

  final List<Map<String, dynamic>> _seedUsers = [
    {
      'email': 'test1@gmail.com',
      'password': '123456',
      'role': UserRole.customer,
    },
    {
      'email': 'test2@gmail.com',
      'password': '123456',
      'role': UserRole.merchant,
    },
    {'email': 'test3@gmail.com', 'password': '123456', 'role': UserRole.driver},
    {'email': 'admin@gmail.com', 'password': '123456', 'role': UserRole.admin},
  ];

  Future<void> seedUsers() async {
    for (var user in _seedUsers) {
      try {
        AuthResponse? res;

        // 1. Try to Login first (to check existence and get UID)
        try {
          res = await _supabase.auth.signInWithPassword(
            email: user['email'],
            password: user['password'],
          );
          debugPrint('Verified ${user['email']} exists and logged in.');
        } catch (e) {
          // User doesn't exist, create them
          debugPrint('${user['email']} not found. Creating...');
          try {
            res = await _supabase.auth.signUp(
              email: user['email'],
              password: user['password'],
            );
          } catch (createError) {
            debugPrint("Failed to create user ${user['email']}: $createError");
          }
        }

        // 2. If we have a user (either logged in or just created), check/create Supabase doc
        if (res != null && res.user != null) {
          final uid = res.user!.id;
          final doc = await _supabase
              .from('users')
              .select()
              .eq('id', uid)
              .maybeSingle();

          if (doc == null) {
            debugPrint('Repairing Supabase document for ${user['email']}...');
            UserModel newUser = UserModel(
              uid: uid,
              email: user['email'],
              roles: [user['role']],
              createdAt: DateTime.now(),
            );
            await _supabase.from('users').insert(newUser.toMap());
            debugPrint('Supabase document repaired.');
          } else {
            debugPrint('Supabase document exists for ${user['email']}.');
          }

          // Sign out to prepare for next iteration
          await _supabase.auth.signOut();
        }
      } catch (e) {
        debugPrint('General error seeding ${user['email']}: $e');
      }
    }

    // YÊU CẦU: Tự động kiểm tra xem tài khoản ít thì tạo 100 users
    try {
      final totalUsers = await _supabase.from('users').count(CountOption.exact);
      if (totalUsers < 50) {
        debugPrint('Số lượng người dùng hiện tại là $totalUsers, quá ít! Bắt đầu tạo 100 người dùng tự động...');
        await _seed100MockUsers();
      } else {
        debugPrint('Dữ liệu đã có đủ $totalUsers người dùng, bỏ qua tự tạo.');
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra số lượng DB: $e');
    }
  }

  Future<void> _seed100MockUsers() async {
    final roles = [
      UserRole.customer,
      UserRole.customer,
      UserRole.customer,
      UserRole.driver,
      UserRole.merchant,
    ];
    final random = Random();

    for (int i = 0; i < 100; i++) {
      final epoch = DateTime.now().millisecondsSinceEpoch;
      final email = 'mockuser${i}_$epoch@test.com';
      final password = '12345678';
      final randomRole = roles[random.nextInt(roles.length)];

      try {
        // Đăng ký tạo identity trong auth.users
        final res = await _supabase.auth.signUp(
          email: email, 
          password: password
        );
        
        if (res.user != null) {
          final uid = res.user!.id;
          
          UserModel newUser = UserModel(
            uid: uid,
            email: email,
            roles: [randomRole],
            createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
            name: "Mock User $i",
          );
          
          // Cập nhật record bên public.users (upsert tránh lỗi dup key)
          await _supabase.from('users').upsert(newUser.toMap());
          
          // Nếu user là customer, tạo thêm các order ảo cho đồ thị doanh thu
          if (randomRole == UserRole.customer) {
             int orderCount = 1 + random.nextInt(4); // 1-4 orders
             for (int j = 0; j < orderCount; j++) {
                final price = 50000 + random.nextInt(200000);
                final backDays = random.nextInt(7); // Dàn đều 7 ngày qua
                
                await _supabase.from('orders').insert({
                   'customer_id': uid,
                   'total_price': price,
                   'status': 'Completed',
                   'merchant_name': 'Cửa hàng ${random.nextInt(10)}',
                   'service_type': 'Food',
                   'items_summary': '1x Sản phẩm mẫu',
                   'created_at': DateTime.now()
                       .subtract(Duration(days: backDays, hours: random.nextInt(12)))
                       .toIso8601String(),
                });
             }
          }

          // Sign out ngay lập tức để không giữ session và dẹp đường tạo tiếp
          await _supabase.auth.signOut();
        }
        
        // Cố tình chờ một khoảng nhỏ để tránh API Rate Limit (Too many signups) từ máy chủ
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (i > 0 && i % 10 == 0) {
          debugPrint('Đã tạo thành công $i / 100 tài khoản mẫu...');
        }
      } catch (e) {
        debugPrint("Lỗi tạo user mock thứ $i: $e");
      }
    }
    debugPrint('Quá trình tự động tạo 100 User và Giao dịch hoàn tất!');
  }
}
