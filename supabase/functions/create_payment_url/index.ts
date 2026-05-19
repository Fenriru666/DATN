// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const VNP_TMN_CODE = (Deno.env.get("VNP_TMN_CODE") || "TODBMCDE").trim();
const VNP_HASH_SECRET = (Deno.env.get("VNP_HASH_SECRET") || "XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS").trim();
const VNP_URL = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
const VNP_RETURN_URL = "https://dklvrzwvayhtcjslsnzr.supabase.co/return";

// Mã hóa TUYỆT ĐỐI theo chuẩn VNPAY
function encodeVnpayValue(value: string) {
  return encodeURIComponent(value)
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A')
    .replace(/%20/g, '+');
}

// Lấy giờ Việt Nam an toàn tuyệt đối, bỏ qua múi giờ server
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
  const p: Record<string, string> = {};
  parts.forEach(({ type, value }) => { p[type] = value; });
  
  // Xử lý case '24h' của một số engine JS cũ
  let hour = p.hour;
  if (hour === '24') hour = '00';

  return `${p.year}${p.month}${p.day}${hour}${p.minute}${p.second}`;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return new Response("Method Not Allowed", { status: 405 });
    
    const { amount, description, ipAddr } = await req.json();

    const vnpParams: Record<string, string> = {
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
      vnp_IpAddr: ipAddr || '13.160.92.202',
      vnp_CreateDate: getVnpayDate(0),
      vnp_ExpireDate: getVnpayDate(15),
    };

    const sortedKeys = Object.keys(vnpParams).sort();
    const signData = sortedKeys.map(key => {
      return `${encodeVnpayValue(key)}=${encodeVnpayValue(vnpParams[key])}`;
    }).join('&');

    const encoder = new TextEncoder();
    const cryptoKey = await crypto.subtle.importKey(
      "raw", encoder.encode(VNP_HASH_SECRET), { name: "HMAC", hash: "SHA-512" }, false, ["sign"]
    );
    const signature = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(signData));
    
    const secureHash = Array.from(new Uint8Array(signature))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    const paymentUrl = `${VNP_URL}?${signData}&vnp_SecureHash=${secureHash}`;

    // Ghi log để debug trên Supabase
    console.log("--- GENERATE URL SUCCESS ---");
    console.log("TxnRef:", vnpParams.vnp_TxnRef);
    console.log("SignData:", signData);
    
    return new Response(JSON.stringify({ paymentUrl }), { headers: { "Content-Type": "application/json" } });
  } catch (error) {
    console.error("Lỗi:", error);
    return new Response(JSON.stringify({ error: "Failed to generate URL" }), { status: 500 });
  }
});
