// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";

const MOMO_SECRET_KEY = (Deno.env.get("MOMO_SECRET_KEY") || "MOMO").trim();

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ message: "Invalid method" }), { status: 405 });
    }

    const payload = await req.json();
    console.log("Received MoMo IPN:", payload);

    const {
      partnerCode, orderId, requestId, amount, orderInfo,
      orderType, transId, resultCode, message, payType,
      responseTime, extraData, signature
    } = payload;

    // Verify Signature
    // rawSignature format: accessKey=...&amount=...&extraData=...&message=...&orderId=...&orderInfo=...&orderType=...&partnerCode=...&payType=...&requestId=...&responseTime=...&resultCode=...&transId=...
    const accessKey = Deno.env.get("MOMO_ACCESS_KEY") || "MOMO";
    const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&message=${message}&orderId=${orderId}&orderInfo=${orderInfo}&orderType=${orderType}&partnerCode=${partnerCode}&payType=${payType}&requestId=${requestId}&responseTime=${responseTime}&resultCode=${resultCode}&transId=${transId}`;

    const encoder = new TextEncoder();
    const keyData = encoder.encode(MOMO_SECRET_KEY);
    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const generatedSignatureBuffer = await crypto.subtle.sign(
      "HMAC",
      cryptoKey,
      encoder.encode(rawSignature)
    );

    const generatedSignature = Array.from(new Uint8Array(generatedSignatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    if (generatedSignature !== signature) {
      console.error("Invalid MoMo Signature!", { expected: generatedSignature, received: signature });
      return new Response(JSON.stringify({ message: "Invalid signature" }), { status: 400 });
    }

    if (resultCode !== 0) {
      console.log(`MoMo transaction failed: ${message}`);
      // Return 204 to acknowledge receipt without error
      return new Response(null, { status: 204 });
    }

    // Process Business Logic
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (orderId.startsWith('TOPUP_')) {
      const parts = orderId.split('_');
      if (parts.length >= 2) {
        const userId = parts[1];
        
        // Call RPC to top up wallet
        const { error } = await supabase.rpc('top_up_wallet', {
          p_user_id: userId,
          p_amount: amount,
          p_description: "Nạp tiền qua MoMo",
        });

        if (error) {
          console.error("Supabase RPC Error:", error);
          return new Response(JSON.stringify({ message: "Database Error" }), { status: 500 });
        }
        console.log(`Top up successful for ${userId} amount ${amount}`);
      }
    } else if (orderId.startsWith('ORDER_')) {
      // TODO: Update order state
      console.log(`Order ${orderId} paid successfully via MoMo.`);
    }

    // Always return 204 No Content for successful IPN processing
    return new Response(null, { status: 204 });
  } catch (err) {
    console.error("IPN Error:", err);
    return new Response(JSON.stringify({ message: "Internal Server Error" }), { status: 500 });
  }
});
