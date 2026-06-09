import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  assertOrderAccess,
  checkMidtransTransactionStatus,
  fetchLatestPayment,
  fetchOrder,
  getMidtransServerKey,
  HttpError,
  normalizeTransactionStatus,
  paymentMethodLabel,
  providerOrderId,
  requireAuth,
  updateOrderToScheduled,
  writePayment,
} from "../_shared/midtrans.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    const context = await requireAuth(req);
    const body = await req.json() as Record<string, unknown>;
    console.log("CHECK MIDTRANS RECEIVED BODY", body);
    console.log("CHECK MIDTRANS AUTHENTICATED USER", context.user.id);
    const orderId =
      (body.order_id ?? body.orderId)?.toString().trim() ?? "";
    console.log("CHECK MIDTRANS PARSED ORDER ID", orderId);
    if (!orderId) {
      throw new HttpError(400, "order_id_missing", "Order ID belum tersedia.");
    }

    const order = await fetchOrder(context.admin, orderId);
    assertOrderAccess(context, order);
    const payment = await fetchLatestPayment(context.admin, orderId);

    if (!payment) {
      throw new HttpError(
        404,
        "payment_not_found",
        "Data pembayaran tidak ditemukan.",
      );
    }
    if (payment.status === "paid") {
      return jsonResponse({
        status: "paid",
        is_paid: true,
        order_status: order.status,
        midtrans_status: "settlement",
        payment_method: payment.payment_method ?? "Midtrans Sandbox",
      });
    }

    const serverKey = getMidtransServerKey();
    const midtransOrderId =
      payment.provider_order_id?.toString() || providerOrderId(order);
    console.log("CHECK MIDTRANS PROVIDER ORDER ID", midtransOrderId);

    const result = await checkMidtransTransactionStatus(
      serverKey,
      midtransOrderId,
    );
    console.log("CHECK MIDTRANS RAW STATUS", result.transactionStatus);
    console.log("CHECK MIDTRANS NORMALIZED STATUS", result.normalizedStatus);

    if (result.normalizedStatus === "paid") {
      // Update payment to paid and order to scheduled
      await updateOrderToScheduled(
        context.admin,
        order,
        payment,
        result.paymentMethod,
        result.paidAt,
        midtransOrderId,
      );

      return jsonResponse({
        status: "paid",
        is_paid: true,
        order_status: "scheduled",
        midtrans_status: result.transactionStatus,
        payment_method: result.paymentMethod,
      });
    }

    if (result.normalizedStatus === "pending") {
      return jsonResponse({
        status: "pending",
        is_paid: false,
        midtrans_status: result.transactionStatus,
        payment_method: result.paymentMethod,
      });
    }

    // expired / cancelled / failed — update payment status, keep order as pending_payment for retry
    await writePayment(
      context.admin,
      payment,
      {
        order_id: order.id,
        status: result.normalizedStatus,
        provider: "midtrans",
        payment_method: result.paymentMethod,
        amount: Number(order.total_amount),
      },
      {
        provider_order_id: midtransOrderId,
      },
    );
    console.log("CHECK MIDTRANS PAYMENT UPDATE", {
      order_id: order.id,
      payment_status: result.normalizedStatus,
    });

    return jsonResponse({
      status: result.normalizedStatus,
      is_paid: false,
      midtrans_status: result.transactionStatus,
      payment_method: result.paymentMethod,
    });
  } catch (error) {
    if (error instanceof HttpError) {
      return jsonResponse(
        {
          error: error.message,
          code: error.code,
          details: error.details,
        },
        error.status,
      );
    }

    console.error("CHECK MIDTRANS PAYMENT ERROR", error);
    return jsonResponse(
      {
        error: "Status pembayaran Midtrans gagal diperiksa.",
        code: "internal_error",
      },
      500,
    );
  }
});
