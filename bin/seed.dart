import 'package:supabase/supabase.dart';
import 'package:datn/core/models/user_model.dart';
import 'dart:math';

// Cần cấu hình khóa Supabase từ main.dart
const supabaseUrl = 'https://dklvrzwvayhtcjslsnzr.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrbHZyend2YXlodGNqc2xzbnpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzAyNjUsImV4cCI6MjA5MDQ0NjI2NX0.cVSM2dpbqLyI80T0NFYH5o9RGoo6Ret70Rn1VntvVS8';

void main() async {
  print('Bắt đầu quy trình tự động tạo dữ liệu bằng Dart Script...');
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  final random = Random();
  
  final roles = [UserRole.customer, UserRole.driver, UserRole.merchant];
  
  for (int i = 0; i < 15; i++) {
    final email = 'autoseed_${DateTime.now().millisecondsSinceEpoch}_$i@test.com';
    final password = 'password123';
    final role = roles[i % roles.length];
    
    try {
      print('Đang tạo user $i: $email');
      final res = await client.auth.signUp(email: email, password: password);
      
      if (res.user != null) {
        final uid = res.user!.id;
        
        final userMap = {
          'id': uid,
          'email': email,
          'role': role.toString().split('.').last,
          'created_at': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
          'is_approved': true,
          'name': 'Auto User $i',
        };
        
        await client.from('users').upsert(userMap);
        print('✅ Đã tạo profile cho $email');
        
        if (role == UserRole.customer) {
           for (int j = 0; j < 3; j++) {
              // Cố gắng sử dụng nhiều định dạng column name phổ biến để dò cấu trúc DB của bạn
              try {
                await client.from('orders').insert({
                   'userId': uid, // Thử userId
                   'totalPrice': 50000 + random.nextInt(200000), // Thử totalPrice
                   'status': 'Completed',
                   'merchantName': 'Cửa hàng $j',
                   'serviceType': 'Food',
                   'created_at': DateTime.now().subtract(Duration(days: random.nextInt(7))).toIso8601String(),
                });
              } catch (e1) {
                try {
                  await client.from('orders').insert({
                     'user_id': uid, // Thử user_id
                     'total_price': 50000 + random.nextInt(200000), // Thử total_price
                     'status': 'Completed',
                     'merchant_name': 'Cửa hàng $j',
                     'service_type': 'Food',
                     'created_at': DateTime.now().subtract(Duration(days: random.nextInt(7))).toIso8601String(),
                  });
                } catch (e2) {
                   try {
                     await client.from('orders').insert({
                       'userid': uid, // Thử userid
                       'totalprice': 50000 + random.nextInt(200000), // Thử totalprice
                       'status': 'Completed',
                       'merchantname': 'Cửa hàng $j',
                       'servicetype': 'Food',
                       'created_at': DateTime.now().subtract(Duration(days: random.nextInt(7))).toIso8601String(),
                     });
                   } catch (e3) {
                     print('Lỗi insert order: $e3');
                   }
                }
              }
           }
        }
        await client.auth.signOut();
      }
    } catch (e) {
       print('Lỗi tại user $i: $e');
    }
  }
  
  print('✅ Hoàn tất tạo dữ liệu!');
}
