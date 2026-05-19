import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MomoService {
  final String apiUrl = "https://dklvrzwvayhtcjslsnzr.supabase.co/functions/v1/create_momo_url";
  
  Future<String?> generatePaymentUrl({
    required double amount,
    required String description,
    required String userId,
    required String orderId,
  }) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'amount': amount,
          'description': description,
          'userId': userId,
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['paymentUrl']; 
      } else {
        debugPrint('Lỗi tạo đơn MoMo (Server): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('MOMO Exception: $e');
      return null;
    }
  }
}
