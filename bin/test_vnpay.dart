// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final Map<String, String> vnpParams = {
    'vnp_Version': '2.1.0',
    'vnp_Command': 'pay',
    'vnp_TmnCode': 'TODBMCDE',
    'vnp_Locale': 'vn',
    'vnp_CurrCode': 'VND',
    'vnp_TxnRef': '1680000000000',
    'vnp_OrderInfo': 'Thanh toan cuoc xe 12345',
    'vnp_OrderType': 'other',
    'vnp_Amount': '3000000',
    'vnp_ReturnUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html/return',
    'vnp_IpAddr': '127.0.0.1',
    'vnp_CreateDate': '20230518223500'
  };

  final hashSecret = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';

  final sortedKeys = vnpParams.keys.toList()..sort();
  final StringBuffer queryString = StringBuffer();
  final StringBuffer hashData = StringBuffer();

  for (int i = 0; i < sortedKeys.length; i++) {
    final key = sortedKeys[i];
    final value = Uri.encodeComponent(vnpParams[key]!);

    queryString.write('$key=$value');
    hashData.write('$key=${vnpParams[key]}');

    if (i < sortedKeys.length - 1) {
      queryString.write('&');
      hashData.write('&');
    }
  }

  var hmacSha512 = Hmac(sha512, utf8.encode(hashSecret));
  var digest = hmacSha512.convert(utf8.encode(queryString.toString())); // Notice: hashing queryString!

  var digestHashData = hmacSha512.convert(utf8.encode(hashData.toString())); // What if VNPAY wants this?

  print('queryString: ${queryString.toString()}');
  print('hashData: ${hashData.toString()}');
  print('digest (queryString): ${digest.toString()}');
  print('digest (hashData): ${digestHashData.toString()}');
}

