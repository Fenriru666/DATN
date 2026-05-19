const moment = require('moment');
const crypto = require("crypto");
const querystring = require('qs');
const request = require('request'); // We won't use request, just https
const https = require('https');

function sortObject(obj) {
	let sorted = {};
	let str = [];
	let key;
	for (key in obj){
		if (obj.hasOwnProperty(key)) {
		str.push(encodeURIComponent(key));
		}
	}
	str.sort();
    for (key = 0; key < str.length; key++) {
        sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, "+");
    }
    return sorted;
}

function generateDemoUrl() {
    process.env.TZ = 'Asia/Ho_Chi_Minh';
    let date = new Date();
    let createDate = moment(date).format('YYYYMMDDHHmmss');
    
    let ipAddr = '13.160.92.202';
    
    let tmnCode = 'TODBMCDE';
    let secretKey = 'XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS';
    let vnpUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    let returnUrl = 'https://dklvrzwvayhtcjslsnzr.supabase.co/return';
    let orderId = moment(date).format('DDHHmmss');
    let amount = 10000;
    
    let locale = 'vn';
    let currCode = 'VND';
    let vnp_Params = {};
    vnp_Params['vnp_Version'] = '2.1.0';
    vnp_Params['vnp_Command'] = 'pay';
    vnp_Params['vnp_TmnCode'] = tmnCode;
    vnp_Params['vnp_Locale'] = locale;
    vnp_Params['vnp_CurrCode'] = currCode;
    vnp_Params['vnp_TxnRef'] = orderId;
    vnp_Params['vnp_OrderInfo'] = 'Thanh toan cho ma GD:' + orderId;
    vnp_Params['vnp_OrderType'] = 'other';
    vnp_Params['vnp_Amount'] = amount * 100;
    vnp_Params['vnp_ReturnUrl'] = returnUrl;
    vnp_Params['vnp_IpAddr'] = ipAddr;
    vnp_Params['vnp_CreateDate'] = createDate;

    vnp_Params = sortObject(vnp_Params);

    let signData = querystring.stringify(vnp_Params, { encode: false });
    let hmac = crypto.createHmac("sha512", secretKey);
    let signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex"); 
    vnp_Params['vnp_SecureHash'] = signed;
    vnpUrl += '?' + querystring.stringify(vnp_Params, { encode: false });

    console.log("=========================================");
    console.log("CHUỖI HASH DATA (TRƯỚC KHI TẠO CHECKSUM):");
    console.log(signData);
    console.log("=========================================");
    console.log("FULL LOG URL REQUEST:");
    console.log(vnpUrl);
    console.log("=========================================");

    return vnpUrl;
}

async function testUrl() {
    const url = generateDemoUrl();
    console.log("URL:", url);

    return new Promise((resolve) => {
        https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("Redirect/Status:", res.headers.location || res.statusCode);
                resolve();
            });
        });
    });
}

testUrl();
