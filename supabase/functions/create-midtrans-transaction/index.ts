import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  assertOrderAccess,
  checkMidtransTransactionStatus,
  fetchLatestPayment,
  fetchOrder,
  getMidtransServerKey,
  HttpError,
  midtransAuthorization,
  midtransRequest,
  providerOrderId,
  requireAuth,
  updateOrderToScheduled,
  writePayment,
} from "../_shared/midtrans.ts";

const snapEndpoint =
  "https://app.sandbox.midtrans.com/snap/v1/transactions";

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
    console.log("CREATE MIDTRANS RECEIVED BODY", body);
    console.log("CREATE MIDTRANS AUTHENTICATED USER", context.user.id);

    const orderId =
      (body.order_id ?? body.orderId)?.toString().trim() ?? "";
    const grossAmount = Number(body.gross_amount ?? body.grossAmount);
    console.log("CREATE MIDTRANS PARSED REQUEST", {
      order_id: orderId,
      gross_amount: grossAmount,
    });

    if (!orderId) {
      throw new HttpError(400, "order_id_missing", "Order ID belum tersedia.");
    }
    if (!Number.isInteger(grossAmount) || grossAmount <= 0) {
      throw new HttpError(
        400,
        "invalid_request",
        "Nominal pembayaran tidak sesuai.",
      );
    }

    const order = await fetchOrder(context.admin, orderId);
    assertOrderAccess(context, order);
    let payment = await fetchLatestPayment(context.admin, orderId);

    if (Number(order.total_amount) !== grossAmount) {
      throw new HttpError(
        400,
        "amount_mismatch",
        "Nominal pembayaran tidak sesuai.",
      );
    }
    if (["completed", "cancelled"].includes(order.status)) {
      throw new HttpError(
        409,
        "order_not_payable",
        `Pesanan berstatus ${order.status} tidak dapat dibayar.`,
      );
    }
    if (
      ["paid", "scheduled", "in_progress"].includes(order.status) ||
      payment?.status === "paid"
    ) {
      throw new HttpError(409, "already_paid", "Pembayaran sudah selesai.");
    }

    // ── Idempotency: check existing Midtrans transaction before creating ────
    const existingProviderOrderId = payment?.provider_order_id?.toString();
    if (existingProviderOrderId && payment?.status === "pending") {
      console.log("CREATE MIDTRANS EXISTING PROVIDER ORDER ID", existingProviderOrderId);

      const serverKey = getMidtransServerKey();

      // Check Midtrans status for the existing transaction
      try {
        const statusResult = await checkMidtransTransactionStatus(
          serverKey,
          existingProviderOrderId,
        );
        console.log("CREATE MIDTRANS EXISTING STATUS", statusResult.normalizedStatus);

        if (statusResult.normalizedStatus === "paid") {
          // Already paid at Midtrans — update our DB and return paid status
          await updateOrderToScheduled(
            context.admin,
            order,
            payment,
            statusResult.paymentMethod,
            statusResult.paidAt,
            existingProviderOrderId,
          );
          return jsonResponse({
            status: "paid",
            is_paid: true,
            order_status: "scheduled",
          });
        }

        if (statusResult.normalizedStatus === "pending") {
          // Transaction still pending at Midtrans — return existing redirect URL if available
          const existingToken = payment?.snap_token?.toString();
          const existingRedirectUrl = payment?.payment_url?.toString();
          if (existingToken && existingRedirectUrl) {
            return jsonResponse({
              token: existingToken,
              redirect_url: existingRedirectUrl,
            });
          }
          // No stored redirect URL — tell user to check status
          return jsonResponse({
            status: "pending",
            is_paid: false,
            message: "Transaksi Midtrans sudah ada. Silakan cek status pembayaran atau gunakan pembayaran demo.",
          });
        }

        // expired / cancelled / failed — allow retry with new provider_order_id
        console.log("CREATE MIDTRANS EXISTING EXPIRED/FAILED, will create new transaction");
        // Update payment status to reflect Midtrans state
        await writePayment(
          context.admin,
          payment,
          {
            order_id: order.id,
            status: statusResult.normalizedStatus,
            provider: "midtrans",
            payment_method: statusResult.paymentMethod,
            amount: grossAmount,
          },
          { provider_order_id: existingProviderOrderId },
        );
        // Reload payment after status update
        payment = await fetchLatestPayment(context.admin, orderId);
      } catch (midtransError) {
        // If Midtrans status check fails (e.g., 404 = transaction not found),
        // it's safe to proceed with existing token or create new
        console.warn("CREATE MIDTRANS STATUS CHECK FAILED", midtransError);
        const existingToken = payment?.snap_token?.toString();
        const existingRedirectUrl = payment?.payment_url?.toString();
        if (existingToken && existingRedirectUrl) {
          return jsonResponse({
            token: existingToken,
            redirect_url: existingRedirectUrl,
          });
        }
        // Fall through to create new transaction
      }
    }

    // ── Return existing token if still valid ────────────────────────────────
    const existingToken = payment?.snap_token?.toString();
    const existingRedirectUrl = payment?.payment_url?.toString();
    if (existingToken && existingRedirectUrl && payment?.status === "pending") {
      return jsonResponse({
        token: existingToken,
        redirect_url: existingRedirectUrl,
      });
    }

    // ── Ensure payment row exists ───────────────────────────────────────────
    if (!payment) {
      await writePayment(context.admin, null, {
        order_id: order.id,
        status: "pending",
        provider: "midtrans",
        payment_method: "Snap Sandbox",
        amount: grossAmount,
      });
      payment = await fetchLatestPayment(context.admin, orderId);
      if (!payment) {
        throw new HttpError(
          500,
          "payment_write_failed",
          "Data pembayaran gagal disiapkan.",
        );
      }
    }

    // ── Generate unique provider_order_id ────────────────────────────────────
    const serverKey = getMidtransServerKey();
    const shouldCreateNewAttempt = ["failed", "expired", "cancelled"].includes(
      payment?.status ?? "",
    );
    const baseProviderOrderId = providerOrderId(order);
    const midtransOrderId = shouldCreateNewAttempt
      ? `${baseProviderOrderId}-R${Date.now().toString().slice(-6)}`
      : payment?.provider_order_id?.toString() || baseProviderOrderId;

    const profileName =
      context.profile?.full_name?.toString().trim() ||
      context.user.email?.split("@")[0] ||
      "Customer Bersihuy";
    const profileEmail =
      context.profile?.email?.toString().trim() || context.user.email;

    const payload: Record<string, unknown> = {
      transaction_details: {
        order_id: midtransOrderId,
        gross_amount: grossAmount,
      },
      customer_details: {
        first_name: profileName,
        ...(profileEmail ? { email: profileEmail } : {}),
      },
      callbacks: {
        finish: "bersihuy://payment-finish",
      },
    };

    const snap = await midtransRequest(snapEndpoint, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: midtransAuthorization(serverKey),
      },
      body: JSON.stringify(payload),
    });
    console.log("CREATE MIDTRANS SNAP BODY", snap);
    const token = snap.token?.toString();
    const redirectUrl = snap.redirect_url?.toString();

    if (!token || !redirectUrl) {
      throw new HttpError(
        502,
        "invalid_midtrans_response",
        "Midtrans Sandbox tidak mengembalikan tautan pembayaran.",
        snap,
      );
    }

    await writePayment(
      context.admin,
      payment,
      {
        order_id: order.id,
        status: "pending",
        provider: "midtrans",
        payment_method: "Snap Sandbox",
        amount: grossAmount,
      },
      {
        provider_order_id: midtransOrderId,
        payment_url: redirectUrl,
        snap_token: token,
      },
    );

    return jsonResponse({ token, redirect_url: redirectUrl });
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

    console.error("CREATE MIDTRANS TRANSACTION ERROR", error);
    return jsonResponse(
      {
        error: "Transaksi Midtrans Sandbox gagal dibuat.",
        code: "internal_error",
      },
      500,
    );
  }
});
