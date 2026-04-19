import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class VnpayService {
  final String vnpUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
  final String tmnCode = "DUMMY123"; // Mã website tại VNPAY Sandbox (Test)
  final String hashSecret =
      "DUMMYHSHSECRETKEY1234567890ABCDE"; // Chuỗi bí mật Sandbox (Test)

  String generatePaymentUrl({
    required double amount,
    required String description,
  }) {
    final Map<String, String> vnpParams = {};

    vnpParams['vnp_Version'] = '2.1.0';
    vnpParams['vnp_Command'] = 'pay';
    vnpParams['vnp_TmnCode'] = tmnCode;
    vnpParams['vnp_Locale'] = 'vn';
    vnpParams['vnp_CurrCode'] = 'VND';
    vnpParams['vnp_TxnRef'] = DateTime.now().millisecondsSinceEpoch.toString();
    vnpParams['vnp_OrderInfo'] = description;
    vnpParams['vnp_OrderType'] = 'other';
    vnpParams['vnp_Amount'] = (amount * 100).toInt().toString();
    vnpParams['vnp_ReturnUrl'] =
        'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html/return';
    vnpParams['vnp_IpAddr'] = '127.0.0.1';

    final createDate = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    vnpParams['vnp_CreateDate'] = createDate;

    // Sort keys alphabetically
    final sortedKeys = vnpParams.keys.toList()..sort();

    // Build query string and hash data
    final StringBuffer queryString = StringBuffer();
    final StringBuffer hashData = StringBuffer();

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final value = Uri.encodeComponent(vnpParams[key]!);

      queryString.write('$key=$value');
      hashData.write(
        '$key=${vnpParams[key]}',
      ); // VNPAY often computes hash on raw urlencoded string or unencoded values.
      // Note: For VNPAY v2.1.0 standard, hashData is built using urlencoded values as well.

      if (i < sortedKeys.length - 1) {
        queryString.write('&');
        hashData.write('&');
      }
    }

    // Generate Hash
    var hmacSha512 = Hmac(sha512, utf8.encode(hashSecret));
    var digest = hmacSha512.convert(utf8.encode(queryString.toString()));

    final secureHash = digest.toString();
    queryString.write('&vnp_SecureHash=$secureHash');

    return '$vnpUrl?${queryString.toString()}';
  }
}
