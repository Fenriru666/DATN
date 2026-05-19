// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";

const VNP_HASH_SECRET = (Deno.env.get("VNP_HASH_SECRET") || "XZR64R2KOWADPJMB4YZ8QNK15S0YHPJS").trim();

Deno.serve(async (req: Request) => {
  try {
    const url = new URL(req.url);
    const searchParams = url.searchParams;

    if (req.method !== 'GET') {
      return new Response(JSON.stringify({ RspCode: "99", Message: "Invalid method" }), { headers: { "Content-Type": "application/json" } });
    }

    let vnp_SecureHash = searchParams.get('vnp_SecureHash');
    if (!vnp_SecureHash) {
      return new Response(JSON.stringify({ RspCode: "97", Message: "Invalid Signature" }), { headers: { "Content-Type": "application/json" } });
    }

    // Extract parameters and sort them
    const params: Record<string, string> = {};
    for (const [key, value] of searchParams.entries()) {
      if (key !== 'vnp_SecureHash' && key !== 'vnp_SecureHashType') {
        params[key] = value;
      }
    }

    const sortedKeys = Object.keys(params).sort();
    const signData = sortedKeys.map(key => {
      const encodedKey = encodeURIComponent(key).replace(/%20/g, '+');
      const encodedValue = encodeURIComponent(params[key]).replace(/%20/g, '+');
      return `${encodedKey}=${encodedValue}`;
    }).join('&');

    // Create Hash using Web Crypto API to avoid Deno std imports
    const encoder = new TextEncoder();
    const keyData = encoder.encode(VNP_HASH_SECRET);
    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
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
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    if (secureHash !== vnp_SecureHash) {
      console.error("Invalid Checksum!", { secureHash, vnp_SecureHash });
      return new Response(JSON.stringify({ RspCode: "97", Message: "Invalid Signature" }), { headers: { "Content-Type": "application/json" } });
    }

    const vnp_ResponseCode = searchParams.get('vnp_ResponseCode');
    if (vnp_ResponseCode !== '00') {
      console.log("Transaction failed or cancelled");
      return new Response(JSON.stringify({ RspCode: "00", Message: "Confirm Success" }), { headers: { "Content-Type": "application/json" } });
    }

    const vnp_OrderInfo = searchParams.get('vnp_OrderInfo');
    const vnp_Amount = searchParams.get('vnp_Amount');

    if (!vnp_OrderInfo) {
      return new Response(JSON.stringify({ RspCode: "01", Message: "Order Not Found" }), { headers: { "Content-Type": "application/json" } });
    }

    // Supabase Admin Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (vnp_OrderInfo.startsWith('TOPUP_')) {
      const userId = vnp_OrderInfo.replace('TOPUP_', '');
      const amount = parseInt(vnp_Amount || "0") / 100;

      // Call RPC to top up wallet
      const { error } = await supabase.rpc('top_up_wallet', {
        p_user_id: userId,
        p_amount: amount,
        p_description: "Nạp tiền qua VNPAY",
      });

      if (error) {
        console.error("Supabase RPC Error:", error);
        return new Response(JSON.stringify({ RspCode: "99", Message: "Database Error" }), { headers: { "Content-Type": "application/json" } });
      }
    } else if (vnp_OrderInfo.startsWith('ORDER_')) {
      const orderId = vnp_OrderInfo.replace('ORDER_', '');
      console.log(`Order ${orderId} paid successfully via VNPAY.`);
      // Note: order state in Firebase is updated by the Frontend client.
      // We just acknowledge VNPAY here so they stop retrying.
    } else {
      return new Response(JSON.stringify({ RspCode: "01", Message: "Unknown Order Format" }), { headers: { "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({ RspCode: "00", Message: "Confirm Success" }), { headers: { "Content-Type": "application/json" } });
  } catch (err) {
    console.error("IPN Error:", err);
    return new Response(JSON.stringify({ RspCode: "99", Message: "Unknown Error" }), { headers: { "Content-Type": "application/json" } });
  }
});
