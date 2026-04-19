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
    print("User authenticated: ${res.user?.id ?? 'null'}");
    
    final data = await supabase.from('users').select('role, id').limit(5);
    print("Existing roles in database:");
    print(data);
  } catch(e) {
    print("Error: ");
    print(e);
  }
}
