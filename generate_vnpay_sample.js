const crypto = require('crypto');

function encodeVnpayValue(value) {
  return encodeURIComponent(value)
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A')
    .replace(/%20/g, '+');
}

function getVnpayDate(offsetMinutes = 0) {
  const now = new Date();
  now.setMinutes(now.getMinutes() + offsetMinutes);
  
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false
  });
  
  const parts = formatter.formatToParts(now);
  const p = {};
  parts.forEach(({ type, value }) => { p[type] = value; });
  
  let hour = p.hour;
  if (hour === '24') hour = '00';

  return `${p.year}${p.month}${p.day}${hour}${p.minute}${p.second}`;
}

const VNP_TMN_CODE = 'TODBMCDE';
const VNP_HASH_SECRET = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';
const VNP_URL = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
const VNP_RETURN_URL = "https://dklvrzwvayhtcjslsnzr.supabase.co/return";

const amount = 100000;
const description = 'Nap tien vao vi VNPAY';
const ipAddr = '13.160.92.202';

const vnpParams = {
  vnp_Version: '2.1.0',
  vnp_Command: 'pay',
  vnp_TmnCode: VNP_TMN_CODE,
  vnp_Locale: 'vn',
  vnp_CurrCode: 'VND',
  vnp_TxnRef: Date.now().toString(),
  vnp_OrderInfo: description,
  vnp_OrderType: 'other',
  vnp_Amount: (Math.round(amount * 100)).toString(),
  vnp_ReturnUrl: VNP_RETURN_URL,
  vnp_IpAddr: ipAddr,
  vnp_CreateDate: getVnpayDate(0),
  vnp_ExpireDate: getVnpayDate(15),
};

const sortedKeys = Object.keys(vnpParams).sort();
const signData = sortedKeys.map(key => {
  return `${encodeVnpayValue(key)}=${encodeVnpayValue(vnpParams[key])}`;
}).join('&');

const hmac = crypto.createHmac("sha512", VNP_HASH_SECRET);
const secureHash = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

const paymentUrl = `${VNP_URL}?${signData}&vnp_SecureHash=${secureHash}`;

console.log("==================================================");
console.log("CHUỖI HASH DATA (TRƯỚC KHI TẠO CHECKSUM):");
console.log(signData);
console.log("\nFULL LOG URL REQUEST:");
console.log(paymentUrl);
console.log("==================================================");
