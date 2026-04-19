import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUser([User? currentUser]) async {
    final Session? session = _supabase.auth.currentSession;
    final User? user = currentUser ?? session?.user;

    if (user != null) {
      try {
        final data = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          try {
            return UserModel.fromMap(data, user.id);
          } catch (e, st) {
            debugPrint("UserModel parse error: $e\n$st");
            // DO NOT return null here. Throw an exception so the UI shows the real cause!
            throw Exception("Parse Error: $e");
          }
        } else {
          // Self-healing
          UserRole role = UserRole.customer;
          if (user.email!.startsWith('test2')) role = UserRole.merchant;
          if (user.email!.startsWith('test3')) role = UserRole.driver;
          if (user.email!.startsWith('admin')) role = UserRole.admin;

          bool approved = true;
          if (role == UserRole.driver || role == UserRole.merchant) {
            approved =
                false; // Mock data generated users are technically pending too
          }

          UserModel newUser = UserModel(
            uid: user.id,
            email: user.email ?? '',
            name:
                user.userMetadata?['name'] ??
                user.email?.split('@')[0] ??
                'Khách hàng',
            roles: [role],
            createdAt: DateTime.now(),
            isApproved: approved,
          );
          try {
            await _supabase.from('users').insert(newUser.toMap());
            return newUser;
          } catch (e) {
            debugPrint("Failed to auto-create profile: $e");
            throw Exception("Auto-create Error: $e");
          }
        }
      } catch (e, st) {
        debugPrint("Error fetching user data: $e\n$st");
        throw Exception("DB Error: $e");
      }
    }
    return null;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateUserProfile(String name, String phone) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('users')
          .update({'name': name, 'phone': phone})
          .eq('id', user.id);
    } else {
      throw Exception("User not logged in");
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required UserRole role,
    String? referralCode,
    String? driverType,
  }) async {
    try {
      AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) throw Exception("Signup failed, user is null");
      bool approved = true;
      if (role == UserRole.driver || role == UserRole.merchant) {
        approved = false;
      }

      // 1. Generate unique referral code for this new user
      String newReferralCode = _generateReferralCode(email, user.id);

      // 2. Validate inputted referral code if provided
      String? referredByUid;
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        final referrerSnapshot = await _supabase
            .from('users')
            .select('id')
            .eq(
              'referral_code',
              referralCode.trim().toUpperCase(),
            ) // Ensure exact match
            .limit(1)
            .maybeSingle();

        if (referrerSnapshot != null) {
          referredByUid = referrerSnapshot['id'];
        }
      }

      // 3. Create User Model
      UserModel newUser = UserModel(
        uid: user.id,
        email: email,
        roles: [role],
        createdAt: DateTime.now(),
        isApproved: approved,
        referralCode: newReferralCode,
        referredBy: referredByUid,
        driverType: driverType,
      );

      // 4. Save to DB
      await _supabase.from('users').insert(newUser.toMap());

      // 5. Grant Rewards if referredByUid is valid
      if (referredByUid != null) {
        await _grantReferralRewards(
          newUserId: user.id,
          referrerId: referredByUid,
        );
      }
    } catch (e) {
      // Handle or rethrow
      rethrow;
    }
  }

  String _generateReferralCode(String email, String uid) {
    // Basic generator: first 3 letters of email + last 4 chars of UID
    String prefix = email
        .split('@')[0]
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    if (prefix.length > 3) prefix = prefix.substring(0, 3);
    if (prefix.length < 3) prefix = prefix.padRight(3, 'X');

    String suffix = uid.substring(uid.length - 4).toUpperCase();
    return "DATN_$prefix$suffix";
  }

  Future<void> _grantReferralRewards({
    required String newUserId,
    required String referrerId,
  }) async {
    // Reward logic: Supabase Function or direct update (not atomic without RPC, but fine for MVP)
    // To do this safely, we will query existing balances then update.
    try {
      final newUserData = await _supabase
          .from('users')
          .select('wallet_balance')
          .eq('id', newUserId)
          .single();
      final referData = await _supabase
          .from('users')
          .select('wallet_balance')
          .eq('id', referrerId)
          .single();

      final currentNewUserBal = (newUserData['wallet_balance'] ?? 0.0)
          .toDouble();
      final currentReferBal = (referData['wallet_balance'] ?? 0.0).toDouble();

      await _supabase
          .from('users')
          .update({'wallet_balance': currentNewUserBal + 50000.0})
          .eq('id', newUserId);

      await _supabase
          .from('users')
          .update({'wallet_balance': currentReferBal + 50000.0})
          .eq('id', referrerId);

      // Optional: Log it in referrals collection (if we had it, omitting for now)
    } catch (e) {
      debugPrint("Error granting referral rewards: $e");
    }
  }

  Future<void> updateSavedPlace(
    String userId,
    String label,
    Map<String, dynamic> locationData,
  ) async {
    try {
      // In Supabase we might need RPC to update JSONB deeply, or we fetch & save.
      final userRec = await _supabase
          .from('users')
          .select('saved_places')
          .eq('id', userId)
          .single();
      Map<String, dynamic> savedPlaces = userRec['saved_places'] ?? {};
      savedPlaces[label] = locationData;

      await _supabase
          .from('users')
          .update({'saved_places': savedPlaces})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update saved place: $e');
    }
  }
}
