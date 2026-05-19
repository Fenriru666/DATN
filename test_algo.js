const crypto = require('crypto');
const https = require('https');

const vnpParams = {
  'vnp_Amount': '10000000',
  'vnp_Command': 'pay',
  'vnp_CreateDate': '20260519000000',
  'vnp_CurrCode': 'VND',
  'vnp_IpAddr': '127.0.0.1',
  'vnp_Locale': 'vn',
  'vnp_OrderInfo': 'Test',
  'vnp_OrderType': 'other',
  'vnp_ReturnUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html/return',
  'vnp_TmnCode': 'TODBMCDE',
  'vnp_TxnRef': 'TEST123456',
  'vnp_Version': '2.1.0',
};

const secretKey = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';
const sortedKeys = Object.keys(vnpParams).sort();
let hashData = [];
for (const key of sortedKeys) {
  hashData.push(key + '=' + encodeURIComponent(vnpParams[key]).replace(/%20/g, "+"));
}
const signData = hashData.join('&');

// Try SHA512
const hmac512 = crypto.createHmac("sha512", secretKey);
const signed512 = hmac512.update(new Buffer.from(signData, 'utf-8')).digest("hex");
const url512 = `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?${signData}&vnp_SecureHash=${signed512}`;

// Try SHA256
const hmac256 = crypto.createHmac("sha256", secretKey);
const signed256 = hmac256.update(new Buffer.from(signData, 'utf-8')).digest("hex");
const url256 = `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?${signData}&vnp_SecureHash=${signed256}`;

// Try SHA256 with v2.0.0 and raw signData
const vnpParams2 = { ...vnpParams, 'vnp_Version': '2.0.0' };
const sortedKeys2 = Object.keys(vnpParams2).sort();
let hashData2 = [];
let queryData2 = [];
for (const key of sortedKeys2) {
  hashData2.push(key + '=' + vnpParams2[key]); // RAW
  queryData2.push(key + '=' + encodeURIComponent(vnpParams2[key]).replace(/%20/g, "+"));
}
const signData2 = hashData2.join('&');
const queryStr2 = queryData2.join('&');
const hmac256_v2 = crypto.createHmac("sha256", secretKey);
const signed256_v2 = hmac256_v2.update(new Buffer.from(signData2, 'utf-8')).digest("hex");
const url256_v2 = `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?${queryStr2}&vnp_SecureHashType=SHA256&vnp_SecureHash=${signed256_v2}`;

async function checkUrl(url, name) {
    return new Promise((resolve) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (data.includes('Sai chữ ký')) {
                    console.log(`[${name}] Result: Sai chữ ký`);
                } else if (res.statusCode >= 300 && res.statusCode < 400) {
                    console.log(`[${name}] Result: Redirect (Probably Success) to ${res.headers.location}`);
                } else {
                    console.log(`[${name}] Result: SUCCESS or other error (Status ${res.statusCode})`);
                }
                resolve();
            });
        });
    });
}

async function run() {
    await checkUrl(url512, "SHA512");
    await checkUrl(url256, "SHA256");
    await checkUrl(url256_v2, "SHA256 v2.0.0");
}
run();
