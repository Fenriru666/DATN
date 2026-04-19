import 'package:datn/core/models/user_model.dart';
import 'package:datn/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. Auth State Changes Stream Provider (Listens to Supabase User login/logout)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(authServiceProvider)
      .authStateChanges
      .map((state) => state.session?.user);
});

// 3. User Data Provider (Fetches full UserModel from Firestore whenever authState changes)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return null;
  }

  // Need to fetch full profile
  return ref.read(authServiceProvider).getCurrentUser(user);
});
