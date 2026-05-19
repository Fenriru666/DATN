const crypto = require('crypto');
const querystring = require('querystring');

const vnpParams = {
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

const secretKey = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';

// NodeJS implementation as per VNPAY documentation
const sortedKeys = Object.keys(vnpParams).sort();
let hashData = [];
for (const key of sortedKeys) {
  hashData.push(key + '=' + encodeURIComponent(vnpParams[key]).replace(/%20/g, "+"));
}
const signData = hashData.join('&');

const hmac = crypto.createHmac("sha512", secretKey);
const signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex");

console.log('NodeJS SignData: ', signData);
console.log('NodeJS Hash:     ', signed);
