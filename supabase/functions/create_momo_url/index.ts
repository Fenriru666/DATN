// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const MOMO_PARTNER_CODE = (Deno.env.get("MOMO_PARTNER_CODE") || "MOMO").trim();
const MOMO_ACCESS_KEY = (Deno.env.get("MOMO_ACCESS_KEY") || "MOMO").trim();
const MOMO_SECRET_KEY = (Deno.env.get("MOMO_SECRET_KEY") || "MOMO").trim();
const MOMO_URL = "https://test-payment.momo.vn/v2/gateway/api/create";
const MOMO_RETURN_URL = "https://dklvrzwvayhtcjslsnzr.supabase.co/return";
const MOMO_IPN_URL = "https://dklvrzwvayhtcjslsnzr.supabase.co/functions/v1/momo_ipn";

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return new Response("Method Not Allowed", { status: 405 });
    
    const { amount, description, userId, orderId } = await req.json();

    const requestId = Date.now().toString();
    const requestType = "captureWallet";
    const amountStr = Math.round(amount).toString();
    const orderInfo = description;

    const rawSignature = `accessKey=${MOMO_ACCESS_KEY}&amount=${amountStr}&extraData=&ipnUrl=${MOMO_IPN_URL}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${MOMO_PARTNER_CODE}&redirectUrl=${MOMO_RETURN_URL}&requestId=${requestId}&requestType=${requestType}`;

    const encoder = new TextEncoder();
    const cryptoKey = await crypto.subtle.importKey(
      "raw", encoder.encode(MOMO_SECRET_KEY), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
    );
    const signatureBuffer = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(rawSignature));
    
    const signature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    const requestBody = {
      partnerCode: MOMO_PARTNER_CODE,
      partnerName: "SuperApp",
      storeId: "MomoTestStore",
      requestId: requestId,
      amount: parseInt(amountStr),
      orderId: orderId,
      orderInfo: orderInfo,
      redirectUrl: MOMO_RETURN_URL,
      ipnUrl: MOMO_IPN_URL,
      lang: "vi",
      requestType: requestType,
      autoCapture: true,
      extraData: "",
      signature: signature
    };

    const response = await fetch(MOMO_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: JSON.stringify(requestBody)
    });

    const responseData = await response.json();
    if (responseData.resultCode === 0) {
      return new Response(JSON.stringify({ paymentUrl: responseData.payUrl }), { headers: { "Content-Type": "application/json" } });
    } else {
      return new Response(JSON.stringify({ error: responseData.message }), { status: 400 });
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: "Failed to generate MoMo URL" }), { status: 500 });
  }
});
