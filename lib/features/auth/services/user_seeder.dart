import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:flutter/foundation.dart';

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
          final doc = await _supabase.from('users').select().eq('id', uid).maybeSingle();

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
  }
}
