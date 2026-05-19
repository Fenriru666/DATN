// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final vnpParams = {
    'vnp_Amount': '41000000',
    'vnp_Command': 'pay',
    'vnp_CreateDate': '20260518234954',
    'vnp_CurrCode': 'VND',
    'vnp_IpAddr': '127.0.0.1',
    'vnp_Locale': 'vn',
    'vnp_OrderInfo': 'TOPUP_42a799f9a70649bc95a4a9ed2ab3d49a',
    'vnp_OrderType': 'other',
    'vnp_ReturnUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html/return',
    'vnp_TmnCode': 'TODBMCDE',
    'vnp_TxnRef': '1779122994306',
    'vnp_Version': '2.1.0',
  };

  final hashSecret = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';
  final sortedKeys = vnpParams.keys.toList()..sort();
  final StringBuffer queryString = StringBuffer();

  for (int i = 0; i < sortedKeys.length; i++) {
    final key = sortedKeys[i];
    final value = Uri.encodeComponent(vnpParams[key]!);
    queryString.write('$key=$value');
    if (i < sortedKeys.length - 1) {
      queryString.write('&');
    }
  }

  var hmacSha512 = Hmac(sha512, utf8.encode(hashSecret));
  var digest = hmacSha512.convert(utf8.encode(queryString.toString()));

  print('QueryString generated: ${queryString.toString()}');
  print('Expected Hash:         71d3194b90f63a69fbc8176b2a920f1ba9055dc11ea5a99017f855ba5d7b5ee08c0f1284bbdfddfbc303d4d273c06ceae62dde9219936bbab7b89972fdcd6d87');
  print('Generated Hash:        ${digest.toString()}');
  print('Match:                 ${digest.toString() == '71d3194b90f63a69fbc8176b2a920f1ba9055dc11ea5a99017f855ba5d7b5ee08c0f1284bbdfddfbc303d4d273c06ceae62dde9219936bbab7b89972fdcd6d87'}');
}





