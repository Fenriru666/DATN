// @ts-nocheck

const VNP_TMN_CODE = "TODBMCDE";
const VNP_HASH_SECRET = "HABVROG8Y2UB5JIB5PBEMC5ZTNMIG2OV";
const VNP_URL = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
const VNP_RETURN_URL = "https://dklvrzwvayhtcjslsnzr.supabase.co/return";

/**
 * Encode giá trị theo đúng chuẩn VNPay PHP (urlencode).
 * VNPay server xác minh bằng cách URL-encode từng param rồi hash,
 * nên chúng ta phải làm tương tự trước khi ký.
 */
/**
 * Mô phỏng PHP urlencode(): khoảng trắng → '+', ký tự đặc biệt → %XX
 * VNPay server dùng PHP urlencode() khi xác minh chữ ký.
 * encodeURIComponent dùng %20 cho khoảng trắng → phải đổi sang +
 */
function encodeVnpay(value: string): string {
  return encodeURIComponent(value)
    .replace(/%20/g, "+")   // PHP urlencode: space → '+'
    .replace(/!/g, "%21")
    .replace(/'/g, "%27")
    .replace(/\(/g, "%28")
    .replace(/\)/g, "%29")
    .replace(/\*/g, "%2A");
}

// Lấy giờ Việt Nam để tạo vnp_CreateDate / vnp_ExpireDate
function getVnpayDate(offsetMinutes = 0): string {
  const now = new Date();
  now.setMinutes(now.getMinutes() + offsetMinutes);

  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Ho_Chi_Minh",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });

  const parts = formatter.formatToParts(now);
  const p: Record<string, string> = {};
  parts.forEach(({ type, value }) => { p[type] = value; });

  let hour = p.hour;
  if (hour === "24") hour = "00";

  return `${p.year}${p.month}${p.day}${hour}${p.minute}${p.second}`;
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {
    const { amount, description, ipAddr } = await req.json();

    const vnpParams: Record<string, string> = {
      vnp_Version: "2.1.0",
      vnp_Command: "pay",
      vnp_TmnCode: VNP_TMN_CODE,
      vnp_Locale: "vn",
      vnp_CurrCode: "VND",
      vnp_TxnRef: Date.now().toString(),
      vnp_OrderInfo: description,
      vnp_OrderType: "other",
      vnp_Amount: Math.round(amount * 100).toString(),
      vnp_ReturnUrl: VNP_RETURN_URL,
      vnp_IpAddr: ipAddr || "13.160.92.202",
      vnp_CreateDate: getVnpayDate(0),
      vnp_ExpireDate: getVnpayDate(15),
    };

    // ✅ CHUẨN VNPAY: Sort key theo alphabet
    const sortedKeys = Object.keys(vnpParams).sort();

    // ✅ SignData: URL-encode từng key & value (VNPay server dùng PHP urlencode để verify)
    const signData = sortedKeys
      .map((key) => `${encodeVnpay(key)}=${encodeVnpay(vnpParams[key])}`)
      .join("&");

    // ✅ HMAC-SHA512
    const encoder = new TextEncoder();
    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      encoder.encode(VNP_HASH_SECRET),
      { name: "HMAC", hash: "SHA-512" },
      false,
      ["sign"]
    );
    const signature = await crypto.subtle.sign(
      "HMAC",
      cryptoKey,
      encoder.encode(signData)
    );
    const secureHash = Array.from(new Uint8Array(signature))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // ✅ URL dùng cùng signData đã encode (đúng format cho HTTP)
    const paymentUrl = `${VNP_URL}?${signData}&vnp_SecureHash=${secureHash}`;

    console.log("=== VNPAY URL GENERATED ===");
    console.log("TxnRef:", vnpParams.vnp_TxnRef);
    console.log("Amount:", vnpParams.vnp_Amount);
    console.log("OrderInfo:", vnpParams.vnp_OrderInfo);
    console.log("CreateDate:", vnpParams.vnp_CreateDate);
    console.log("SignData:", signData);
    console.log("SecureHash:", secureHash);
    console.log("===========================");

    return new Response(JSON.stringify({ paymentUrl }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Lỗi tạo URL VNPay:", error);
    return new Response(
      JSON.stringify({ error: "Failed to generate URL", detail: String(error) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
