import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  fetchLatestPayment,
  getMidtransServerKey,
  HttpError,
  normalizeTransactionStatus,
  paymentMethodLabel,
  writePayment,
} from "../_shared/midtrans.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// ── SHA-512 signature verification ────────────────────────────────────────────

async function sha512(message: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hashBuffer = await crypto.subtle.digest("SHA-512", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function getAdminClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    throw new HttpError(
      500,
      "supabase_not_configured",
      "Konfigurasi server Supabase belum lengkap.",
    );
  }
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

Deno.serve(async (req: Request) => {
  // Allow CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    const body = await req.json() as Record<string, unknown>;
    console.log("MIDTRANS NOTIFICATION RECEIVED", {
      order_id: body.order_id,
      transaction_status: body.transaction_status,
      fraud_status: body.fraud_status,
      status_code: body.status_code,
    });

    const midtransOrderId = body.order_id?.toString().trim() ?? "";
    const transactionStatus =
      body.transaction_status?.toString().toLowerCase() ?? "";
    const fraudStatus = body.fraud_status?.toString().toLowerCase() ?? "";
    const statusCode = body.status_code?.toString() ?? "";
    const grossAmount = body.gross_amount?.toString() ?? "";
    const signatureKey = body.signature_key?.toString() ?? "";
    const paymentType = body.payment_type?.toString().toLowerCase() ?? "";

    if (!midtransOrderId || !transactionStatus) {
      console.warn("MIDTRANS NOTIFICATION MISSING FIELDS", {
        order_id: midtransOrderId,
        transaction_status: transactionStatus,
      });
      return jsonResponse({ status: "ok", message: "ignored" });
    }

    // ── Verify signature ──────────────────────────────────────────────────
    const serverKey = getMidtransServerKey();
    const expectedSignature = await sha512(
      midtransOrderId + statusCode + grossAmount + serverKey,
    );

    if (signatureKey && expectedSignature !== signatureKey) {
      console.error("MIDTRANS NOTIFICATION SIGNATURE MISMATCH", {
        order_id: midtransOrderId,
        expected_prefix: expectedSignature.slice(0, 16) + "...",
        received_prefix: signatureKey.slice(0, 16) + "...",
      });
      return jsonResponse(
        { error: "Invalid signature." },
        403,
      );
    }
    console.log("MIDTRANS NOTIFICATION SIGNATURE VERIFIED", midtransOrderId);

    // ── Find payment by provider_order_id ──────────────────────────────────
    const admin = getAdminClient();
    const { data: paymentData, error: paymentError } = await admin
      .from("payments")
      .select("*, orders!inner(id, status, total_amount, customer_id, order_number)")
      .eq("provider_order_id", midtransOrderId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (paymentError) {
      console.error("MIDTRANS NOTIFICATION PAYMENT FETCH ERROR", paymentError);
      // Try simpler query without join
      const { data: simplePayment, error: simpleError } = await admin
        .from("payments")
        .select("*")
        .eq("provider_order_id", midtransOrderId)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (simpleError || !simplePayment) {
        console.error("MIDTRANS NOTIFICATION PAYMENT NOT FOUND", {
          provider_order_id: midtransOrderId,
          error: simpleError,
        });
        return jsonResponse({ status: "ok", message: "payment not found" });
      }

      // Process with simple payment data
      await processNotification(
        admin,
        simplePayment,
        null,
        midtransOrderId,
        transactionStatus,
        fraudStatus,
        paymentType,
      );
      return jsonResponse({ status: "ok" });
    }

    if (!paymentData) {
      console.warn("MIDTRANS NOTIFICATION PAYMENT NOT FOUND", {
        provider_order_id: midtransOrderId,
      });
      return jsonResponse({ status: "ok", message: "payment not found" });
    }

    const orderData = paymentData.orders as Record<string, unknown> | null;
    await processNotification(
      admin,
      paymentData,
      orderData,
      midtransOrderId,
      transactionStatus,
      fraudStatus,
      paymentType,
    );

    return jsonResponse({ status: "ok" });
  } catch (error) {
    if (error instanceof HttpError) {
      // Still return 200 to Midtrans to prevent retries for config errors
      console.error("MIDTRANS NOTIFICATION HTTP ERROR", error.message);
      return jsonResponse({ status: "error", message: error.message });
    }

    console.error("MIDTRANS NOTIFICATION ERROR", error);
    return jsonResponse({ status: "error" }, 500);
  }
});

async function processNotification(
  admin: ReturnType<typeof createClient>,
  paymentData: Record<string, unknown>,
  orderData: Record<string, unknown> | null,
  midtransOrderId: string,
  transactionStatus: string,
  fraudStatus: string,
  paymentType: string,
): Promise<void> {
  const normalizedStatus = normalizeTransactionStatus(
    transactionStatus,
    fraudStatus,
  );
  const paymentMethod = paymentMethodLabel(paymentType);
  const paymentId = paymentData.id?.toString();
  const orderId = paymentData.order_id?.toString() ?? "";
  const currentPaymentStatus = paymentData.status?.toString() ?? "";

  console.log("MIDTRANS NOTIFICATION PROCESSING", {
    order_id: orderId,
    payment_id: paymentId,
    provider_order_id: midtransOrderId,
    raw_status: transactionStatus,
    normalized_status: normalizedStatus,
    current_payment_status: currentPaymentStatus,
  });

  // Don't downgrade already-paid payments
  if (currentPaymentStatus === "paid" && normalizedStatus !== "paid") {
    console.log("MIDTRANS NOTIFICATION SKIPPED — payment already paid");
    return;
  }

  if (normalizedStatus === "paid") {
    const paidAt = new Date().toISOString();

    // Update payment to paid
    if (paymentId) {
      const { error: updateError } = await admin
        .from("payments")
        .update({
          status: "paid",
          payment_method: paymentMethod,
          paid_at: paidAt,
        })
        .eq("id", paymentId);
      if (updateError) {
        console.error("MIDTRANS NOTIFICATION PAYMENT UPDATE ERROR", updateError);
      } else {
        console.log("MIDTRANS NOTIFICATION PAYMENT UPDATED TO PAID", paymentId);
      }
    }

    // Update order to scheduled
    const orderStatus = orderData?.status?.toString() ?? "";
    if (["created", "pending_payment"].includes(orderStatus)) {
      const { error: orderError } = await admin
        .from("orders")
        .update({ status: "scheduled" })
        .eq("id", orderId);
      if (orderError) {
        console.error("MIDTRANS NOTIFICATION ORDER UPDATE ERROR", orderError);
      } else {
        console.log("MIDTRANS NOTIFICATION ORDER UPDATED TO SCHEDULED", orderId);
      }
    } else if (!orderData && orderId) {
      // Fallback: try to update order if we couldn't join
      const { error: orderError } = await admin
        .from("orders")
        .update({ status: "scheduled" })
        .eq("id", orderId)
        .in("status", ["created", "pending_payment"]);
      if (orderError) {
        console.error("MIDTRANS NOTIFICATION ORDER FALLBACK UPDATE ERROR", orderError);
      }
    }
  } else if (["expired", "cancelled", "failed"].includes(normalizedStatus)) {
    // Update payment status only
    if (paymentId) {
      const { error: updateError } = await admin
        .from("payments")
        .update({
          status: normalizedStatus,
          payment_method: paymentMethod,
        })
        .eq("id", paymentId);
      if (updateError) {
        console.error("MIDTRANS NOTIFICATION PAYMENT STATUS UPDATE ERROR", updateError);
      } else {
        console.log("MIDTRANS NOTIFICATION PAYMENT STATUS UPDATED", {
          payment_id: paymentId,
          status: normalizedStatus,
        });
      }
    }
  }
}
