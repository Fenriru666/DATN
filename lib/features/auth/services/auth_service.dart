import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            var userModel = UserModel.fromMap(data, user.id);
            if (!userModel.isApproved) {
              // Auto-approve existing accounts for smooth testing
              try {
                await _supabase
                    .from('users')
                    .update({'is_approved': true})
                    .eq('id', user.id);
                userModel = userModel.copyWith(isApproved: true);
              } catch (e) {
                debugPrint("Failed to auto-approve user: $e");
              }
            }
            try {
              final firestoreDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .get();
              if (firestoreDoc.exists && firestoreDoc.data() != null) {
                final fsData = firestoreDoc.data()!;
                userModel = userModel.copyWith(
                  rating: fsData['rating'] != null
                      ? (fsData['rating'] as num).toDouble()
                      : userModel.rating,
                  ratingCount: fsData['ratingCount'] != null
                      ? (fsData['ratingCount'] as num).toInt()
                      : fsData['rating_count'] != null
                          ? (fsData['rating_count'] as num).toInt()
                          : userModel.ratingCount,
                  completedRides: fsData['completedRides'] != null
                      ? (fsData['completedRides'] as num).toInt()
                      : fsData['completed_rides'] != null
                          ? (fsData['completed_rides'] as num).toInt()
                          : userModel.completedRides,
                  tier: fsData['tier'] as String? ?? userModel.tier,
                  loyaltyPoints: fsData['loyaltyPoints'] != null
                      ? (fsData['loyaltyPoints'] as num).toInt()
                      : fsData['loyalty_points'] != null
                          ? (fsData['loyalty_points'] as num).toInt()
                          : userModel.loyaltyPoints,
                  walletBalance: fsData['walletBalance'] != null
                      ? (fsData['walletBalance'] as num).toDouble()
                      : fsData['wallet_balance'] != null
                          ? (fsData['wallet_balance'] as num).toDouble()
                          : userModel.walletBalance,
                );
              }
            } catch (fsError) {
              debugPrint("Failed to merge Firestore user data: $fsError");
            }
            return userModel;
          } catch (e, st) {
            debugPrint("UserModel parse error: $e\n$st");
            throw Exception("Parse Error: $e");
          }
        } else {
          // Self-healing
          UserRole role = UserRole.customer;
          if (user.email!.startsWith('test2')) role = UserRole.merchant;
          if (user.email!.startsWith('test3')) role = UserRole.driver;
          if (user.email!.startsWith('admin')) role = UserRole.admin;

          bool approved = true; // Auto-approve auto-healed accounts

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
      // Auto-approve all roles during sandbox development so testers can log in immediately
      bool approved = true;

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
