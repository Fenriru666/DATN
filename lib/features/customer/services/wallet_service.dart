import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/transaction_model.dart';
import 'package:datn/core/errors/app_exceptions.dart' as app_errors;
import 'package:datn/core/services/notification_sender_service.dart';
import 'package:flutter/foundation.dart';

class WalletService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Stream user's wallet balance
  Stream<double> get walletBalanceStream {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0.0);

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((docs) {
      if (docs.isEmpty) return 0.0;
      return (docs.first['wallet_balance'] ?? 0.0).toDouble();
    });
  }

  /// Stream user's transactions
  Stream<List<TransactionModel>> get transactionsStream {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((docs) {
      return docs
          .map((doc) => TransactionModel.fromMap(doc['id'], doc))
          .toList();
    });
  }

  /// Top up wallet (Simulated)
  Future<void> topUp(double amount) async {
    final uid = currentUserId;
    if (uid == null) throw app_errors.AuthException('User not logged in');
    if (amount <= 0) {
      throw app_errors.ValidationException('Top up amount must be greater than 0');
    }

    try {
      await _supabase.rpc(
        'top_up_wallet',
        params: {
          'p_user_id': uid,
          'p_amount': amount,
          'p_description': 'Top up via ATM/Visa',
        },
      );
    } catch (e) {
      debugPrint('Top Up Error: $e');
      throw app_errors.ServerException('Failed to top up wallet');
    }
  }

  /// Deduct balance for a payment (Ride or Food)
  /// Returns true if successful, throws exception if insufficient balance
  Future<bool> deductBalance(
    double amount,
    String paymentType,
    String description,
  ) async {
    final uid = currentUserId;
    if (uid == null) throw app_errors.AuthException('User not logged in');
    if (amount <= 0) throw app_errors.ValidationException('Invalid payment amount');

    try {
      final response = await _supabase.rpc(
        'deduct_wallet_balance',
        params: {
          'p_user_id': uid,
          'p_amount': amount,
          'p_description': description,
          'p_type': paymentType,
        },
      );

      // We expect the RPC to return true if successful, false or throw exception if fail.
      if (response == false) {
        throw app_errors.ValidationException('Insufficient wallet balance');
      }
      return true;
    } catch (e) {
      if (e.toString().contains('Insufficient')) {
        throw app_errors.ValidationException('Insufficient wallet balance');
      }
      debugPrint('Deduct Balance Error: $e');
      throw app_errors.ServerException('Lỗi hệ thống khi thanh toán.');
    }
  }

  /// Transfer balance from current user to another user
  Future<bool> transferMoney(
    String receiverId,
    double amount,
    String note,
  ) async {
    final senderId = currentUserId;
    if (senderId == null) throw app_errors.AuthException('User not logged in');
    if (senderId == receiverId) {
      throw app_errors.ValidationException('Cannot transfer to yourself');
    }
    if (amount <= 0) throw app_errors.ValidationException('Invalid transfer amount');

    try {
      final response = await _supabase.rpc(
        'transfer_money',
        params: {
          'p_sender_id': senderId,
          'p_receiver_id': receiverId,
          'p_amount': amount,
          'p_note': note,
        },
      );

      if (response == false) {
        throw app_errors.ValidationException('Giao dịch chuyển tiền thất bại');
      }

      // Notify receiver
      final senderData = await _supabase
          .from('users')
          .select('name')
          .eq('id', senderId)
          .single();
      final senderName = senderData['name'] ?? 'Một người bạn';

      NotificationSenderService.notifyUser(
        targetUserId: receiverId,
        title: "Ting Ting! 💸",
        body: "$senderName vừa chuyển cho bạn $amount VND. Lời nhắn: $note",
      ).catchError((e) => debugPrint("Error notifying receiver: $e"));

      return true;
    } catch (e) {
      if (e.toString().contains('Insufficient')) {
        throw app_errors.ValidationException('Số dư ví không đủ để chuyển');
      }
      debugPrint('Transfer Money Error: $e');
      throw app_errors.ServerException('Lỗi hệ thống khi chuyển giao dịch.');
    }
  }

  /// Find user by email or phone for transfer
  Future<Map<String, dynamic>?> findUserForTransfer(String query) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final trimmedQuery = query.trim();

    try {
      // Check email or phone using postgREST OR syntax
      final result = await _supabase
          .from('users')
          .select()
          .or('email.eq.$trimmedQuery,phone.eq.$trimmedQuery')
          .limit(1);

      if (result.isNotEmpty) {
        final doc = result.first;
        if (doc['id'] == uid) {
          throw app_errors.ValidationException("Không thể chuyển tiền cho chính mình");
        }
        return doc;
      }
    } catch (e) {
      debugPrint('Find User Error: $e');
      if (e is app_errors.ValidationException) rethrow;
    }
    return null;
  }
}
