const crypto = require('crypto');

const VNP_HASH_SECRET = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';

const vnpParams = {
  vnp_Amount: '1000000',
  vnp_Command: 'pay',
  vnp_CreateDate: '20260519194544',
  vnp_CurrCode: 'VND',
  vnp_ExpireDate: '20260519200044',
  vnp_IpAddr: '13.160.92.202',
  vnp_Locale: 'vn',
  vnp_OrderInfo: 'TOPUP_123',
  vnp_OrderType: 'other',
  vnp_ReturnUrl: 'https://dklvrzwvayhtcjslsnzr.supabase.co/return',
  vnp_TmnCode: 'TODBMCDE',
  vnp_TxnRef: '1779194744109',
  vnp_Version: '2.1.0'
};

function encodeVnpayValue(value) {
  return encodeURIComponent(value)
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A')
    .replace(/%20/g, '+');
}

const sortedKeys = Object.keys(vnpParams).sort();
const signData = sortedKeys.map(key => {
  return `${encodeVnpayValue(key)}=${encodeVnpayValue(vnpParams[key])}`;
}).join('&');

const hmac = crypto.createHmac('sha512', VNP_HASH_SECRET);
const secureHash = hmac.update(signData).digest('hex');

console.log('Local Hash:', secureHash);
console.log('Sign Data:', signData);
