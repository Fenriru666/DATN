// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";

const VNP_HASH_SECRET = "HABVROG8Y2UB5JIB5PBEMC5ZTNMIG2OV";

Deno.serve(async (req: Request) => {
  try {
    const url = new URL(req.url);
    const searchParams = url.searchParams;

    if (req.method !== "GET") {
      return json({ RspCode: "99", Message: "Invalid method" });
    }

    // Lấy vnp_SecureHash trước khi xử lý các param khác
    const vnp_SecureHash = searchParams.get("vnp_SecureHash");
    if (!vnp_SecureHash) {
      console.error("IPN: Missing vnp_SecureHash");
      return json({ RspCode: "97", Message: "Invalid Signature" });
    }

    // ✅ Thu thập tất cả params, loại trừ các hash field
    const params: Record<string, string> = {};
    for (const [key, value] of searchParams.entries()) {
      if (key !== "vnp_SecureHash" && key !== "vnp_SecureHashType") {
        params[key] = value; // searchParams.get() đã tự decode, giữ nguyên raw value
      }
    }

    // ✅ CHUẨN VNPAY: Sắp xếp key theo alphabet
    const sortedKeys = Object.keys(params).sort();

    // ✅ CHUẨN VNPAY: SignData = raw key=value, KHÔNG URL-encode
    const signData = sortedKeys.map((key) => `${key}=${params[key]}`).join("&");

    console.log("IPN SignData (raw):", signData);
    console.log("IPN vnp_SecureHash from VNPay:", vnp_SecureHash);

    // ✅ HMAC-SHA512 với signData RAW
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

    const computedHash = Array.from(new Uint8Array(signature))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    console.log("IPN computedHash:", computedHash);

    // ✅ So sánh hash (case-insensitive)
    if (computedHash.toLowerCase() !== vnp_SecureHash.toLowerCase()) {
      console.error("IPN: Checksum MISMATCH!", {
        computed: computedHash,
        received: vnp_SecureHash,
      });
      return json({ RspCode: "97", Message: "Invalid Signature" });
    }

    console.log("IPN: Signature OK ✅");

    // Kiểm tra kết quả giao dịch
    const vnp_ResponseCode = searchParams.get("vnp_ResponseCode");
    if (vnp_ResponseCode !== "00") {
      console.log("IPN: Transaction failed/cancelled, ResponseCode:", vnp_ResponseCode);
      // Vẫn trả về 00 để VNPay biết ta đã nhận được IPN
      return json({ RspCode: "00", Message: "Confirm Success" });
    }

    const vnp_OrderInfo = searchParams.get("vnp_OrderInfo");
    const vnp_Amount = searchParams.get("vnp_Amount");

    if (!vnp_OrderInfo) {
      return json({ RspCode: "01", Message: "Order Not Found" });
    }

    // Supabase Admin Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (vnp_OrderInfo.startsWith("TOPUP_")) {
      const userId = vnp_OrderInfo.replace("TOPUP_", "");
      const amount = parseInt(vnp_Amount || "0") / 100;

      console.log(`IPN: Top-up wallet for user=${userId}, amount=${amount}`);

      const { error } = await supabase.rpc("top_up_wallet", {
        p_user_id: userId,
        p_amount: amount,
        p_description: "Nạp tiền qua VNPAY",
      });

      if (error) {
        console.error("IPN: Supabase RPC Error:", error);
        return json({ RspCode: "99", Message: "Database Error" });
      }

      console.log("IPN: Top-up success ✅");
    } else if (vnp_OrderInfo.startsWith("ORDER_")) {
      const orderId = vnp_OrderInfo.replace("ORDER_", "");
      console.log(`IPN: Order ${orderId} paid successfully via VNPAY.`);
      // Frontend tự cập nhật trạng thái đơn hàng trong Firebase
    } else {
      console.error("IPN: Unknown order format:", vnp_OrderInfo);
      return json({ RspCode: "01", Message: "Unknown Order Format" });
    }

    return json({ RspCode: "00", Message: "Confirm Success" });
  } catch (err) {
    console.error("IPN: Unexpected error:", err);
    return json({ RspCode: "99", Message: "Unknown Error" });
  }
});

function json(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
  });
}
