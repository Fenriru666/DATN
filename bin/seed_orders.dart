import 'package:supabase/supabase.dart';
import 'dart:math';

void main() async {
  final supabase = SupabaseClient('https://dklvrzwvayhtcjslsnzr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrbHZyend2YXlodGNqc2xzbnpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzAyNjUsImV4cCI6MjA5MDQ0NjI2NX0.cVSM2dpbqLyI80T0NFYH5o9RGoo6Ret70Rn1VntvVS8');
  
  try {
    print('Fetching customers...');
    final users = await supabase.from('users').select('id, role').limit(50);
    final customers = users.where((u) => u['role'] == 'customer').toList();
    if (customers.isEmpty) {
        print('No customers found');
        return;
    }
    
    print('Generating dummy orders...');
    final random = Random();
    int count = 0;
    
    for (var customer in customers) {
      final uid = customer['id'];
      int orderCount = 2 + random.nextInt(4); // 2-5 orders per customer
      for (int j = 0; j < orderCount; j++) {
        final price = 50000 + random.nextInt(200000);
        final backDays = random.nextInt(7); // past 7 days
                
        await supabase.from('orders').insert({
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
        count++;
      }
    }
    print('Inserted $count orders successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
