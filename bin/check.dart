import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://dklvrzwvayhtcjslsnzr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrbHZyend2YXlodGNqc2xzbnpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzAyNjUsImV4cCI6MjA5MDQ0NjI2NX0.cVSM2dpbqLyI80T0NFYH5o9RGoo6Ret70Rn1VntvVS8');
  try {
    print('Testing query...');
    final orders = await supabase.from('orders')
          .select('total_price, created_at')
          .eq('status', 'Completed')
          .order('created_at', ascending: false)
          .limit(2000);
    print('Orders count: ${orders.length}');
    if (orders.isNotEmpty) {
      print('First order: ${orders.first}');
    }
    
    // Also test users count like getSystemStats
    final usersCount = await supabase.from('users').count(CountOption.exact);
    print('Users Count: $usersCount');
  } catch (e, st) {
    print('Error: $e');
    print('$st');
  }
}
