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
    'vnp_TxnRef': '123456',
    'vnp_OrderInfo': 'TESTORDER',
    'vnp_OrderType': 'other',
    'vnp_Amount': '1000000',
    'vnp_ReturnUrl': 'https://dklvrzwvayhtcjslsnzr.supabase.co/return',
    'vnp_IpAddr': '127.0.0.1',
    'vnp_CreateDate': '20260519065118',
  };

  final hashSecret = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';

  final sortedKeys = vnpParams.keys.toList()..sort();
  final StringBuffer queryString = StringBuffer();
  final StringBuffer hashData = StringBuffer();

  for (int i = 0; i < sortedKeys.length; i++) {
    final key = sortedKeys[i];
    final value = Uri.encodeQueryComponent(vnpParams[key]!);

    queryString.write('$key=$value');
    hashData.write('$key=${vnpParams[key]}');

    if (i < sortedKeys.length - 1) {
      queryString.write('&');
      hashData.write('&');
    }
  }

  var hmacSha512 = Hmac(sha512, utf8.encode(hashSecret));
  
  // Test 1: Hash query string using encodeQueryComponent
  var digest1 = hmacSha512.convert(utf8.encode(queryString.toString()));
  print('SignData (encoded): ${queryString.toString()}');
  print('Hash (encoded): $digest1');
  
  // Test 2: Hash hashData using unencoded values
  var digest2 = hmacSha512.convert(utf8.encode(hashData.toString()));
  print('SignData (unencoded): ${hashData.toString()}');
  print('Hash (unencoded): $digest2');

  // Test 3: Dart Uri.encodeComponent (currently in vnpay_service)
  final StringBuffer queryString2 = StringBuffer();
  for (int i = 0; i < sortedKeys.length; i++) {
    final key = sortedKeys[i];
    final value = Uri.encodeComponent(vnpParams[key]!);
    queryString2.write('$key=$value');
    if (i < sortedKeys.length - 1) {
      queryString2.write('&');
    }
  }
  var digest3 = hmacSha512.convert(utf8.encode(queryString2.toString()));
  print('SignData (encodeComponent): ${queryString2.toString()}');
  print('Hash (encodeComponent): $digest3');
}

