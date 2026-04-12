import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://dklvrzwvayhtcjslsnzr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrbHZyend2YXlodGNqc2xzbnpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzAyNjUsImV4cCI6MjA5MDQ0NjI2NX0.cVSM2dpbqLyI80T0NFYH5o9RGoo6Ret70Rn1VntvVS8'
  );

  try {
    final res = await supabase.auth.signInWithPassword(
      email: 'test1@gmail.com',
      password: '123456',
    );
    final uid = res.user?.id;

    final rolesToTest = ['customer', 'merchant', 'driver', 'admin', 'Customer'];
    for (var r in rolesToTest) {
      try {
        await supabase.from('users').update({'role': r}).eq('id', uid!);
        print("Success setting role: " + r);
      } catch (e) {
        print("Failed to set role " + r + ": " + e.toString());
      }
    }
    
    // restore
    await supabase.from('users').update({'role': 'customer'}).eq('id', uid!);

  } catch(e) {
    print("Error: " + e.toString());
  }
}
