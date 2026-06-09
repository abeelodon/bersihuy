import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
  }
}

export type AuthContext = {
  admin: SupabaseClient;
  user: User;
  profile: Record<string, unknown> | null;
};

export type OrderRow = Record<string, unknown> & {
  id: string;
  customer_id: string;
  order_number: string;
  status: string;
  total_amount: number;
};

export type PaymentRow = Record<string, unknown> & {
  id?: string;
  order_id: string;
  status: string;
  provider: string;
  amount: number;
};

export async function requireAuth(req: Request): Promise<AuthContext> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = req.headers.get("Authorization");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    throw new HttpError(
      500,
      "supabase_not_configured",
      "Konfigurasi server Supabase belum lengkap.",
    );
  }
  if (!authorization?.startsWith("Bearer ")) {
    throw new HttpError(401, "unauthorized", "Sesi pengguna tidak tersedia.");
  }

  const token = authorization.slice("Bearer ".length);
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(token);

  if (userError || !user) {
    throw new HttpError(401, "unauthorized", "Sesi pengguna tidak valid.");
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("id, full_name, email, role")
    .eq("id", user.id)
    .maybeSingle();

  if (profileError) {
    console.error("PROFILE FETCH ERROR", profileError);
  }

  return {
    admin,
    user,
    profile: profile as Record<string, unknown> | null,
  };
}

export function assertOrderAccess(
  context: AuthContext,
  order: OrderRow,
): void {
  const role = context.profile?.role?.toString();
  if (order.customer_id !== context.user.id && role !== "admin") {
    throw new HttpError(403, "forbidden", "Akses pesanan tidak valid.");
  }
}

export async function fetchOrder(
  admin: SupabaseClient,
  orderId: string,
): Promise<OrderRow> {
  const { data, error } = await admin
    .from("orders")
    .select("*")
    .eq("id", orderId)
    .maybeSingle();

  console.log("ORDER QUERY RESULT", {
    order_id: orderId,
    found: Boolean(data),
    order: data,
    error,
  });

  if (error) {
    console.error("ORDER FETCH ERROR", error);
    throw new HttpError(
      500,
      "order_fetch_failed",
      `Data pesanan gagal dimuat: ${shortReason(error.message)}`,
    );
  }
  if (!data) {
    throw new HttpError(
      404,
      "order_not_found",
      "Data pesanan gagal dimuat: order tidak ditemukan.",
    );
  }

  return data as OrderRow;
}

export async function fetchLatestPayment(
  admin: SupabaseClient,
  orderId: string,
): Promise<PaymentRow | null> {
  const { data, error } = await admin
    .from("payments")
    .select("*")
    .eq("order_id", orderId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  console.log("PAYMENT QUERY RESULT", {
    order_id: orderId,
    found: Boolean(data),
    payment: data,
    error,
  });

  if (error) {
    console.error("PAYMENT FETCH ERROR", error);
    throw new HttpError(
      500,
      "payment_fetch_failed",
      "Data pembayaran gagal dimuat.",
    );
  }

  return data as PaymentRow | null;
}

export function getMidtransServerKey(): string {
  const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY")?.trim();
  console.log("Midtrans key configured", Boolean(serverKey));
  if (!serverKey || serverKey.length === 0) {
    throw new HttpError(
      503,
      "midtrans_not_configured",
      "Midtrans Sandbox belum dikonfigurasi.",
    );
  }
  return serverKey;
}

export function midtransAuthorization(serverKey: string): string {
  return `Basic ${btoa(`${serverKey}:`)}`;
}

export function providerOrderId(order: OrderRow): string {
  const normalized = order.order_number.replace(/[^A-Za-z0-9_-]/g, "-");
  return normalized.slice(0, 50);
}

// ── Shared status normalization ───────────────────────────────────────────────

export function normalizeTransactionStatus(
  transactionStatus: string,
  fraudStatus: string,
): string {
  if (
    (transactionStatus === "capture" && fraudStatus !== "deny") ||
    transactionStatus === "settlement"
  ) {
    return "paid";
  }
  if (transactionStatus === "pending" || transactionStatus === "authorize") {
    return "pending";
  }
  if (transactionStatus === "expire") return "expired";
  if (transactionStatus === "cancel") return "cancelled";
  if (transactionStatus === "deny" || transactionStatus === "failure") {
    return "failed";
  }
  if (transactionStatus === "refund" || transactionStatus === "partial_refund") {
    return "refunded";
  }
  return "failed";
}

export function paymentMethodLabel(paymentType: string): string {
  if (!paymentType) return "Snap Sandbox";
  if (paymentType === "qris") return "QRIS Sandbox";
  return `${paymentType.replaceAll("_", " ")} / Midtrans Sandbox`;
}

// ── Check existing Midtrans transaction status ────────────────────────────────

const statusEndpoint = "https://api.sandbox.midtrans.com/v2";

export async function checkMidtransTransactionStatus(
  serverKey: string,
  midtransOrderId: string,
): Promise<{
  normalizedStatus: string;
  transactionStatus: string;
  fraudStatus: string;
  paymentMethod: string;
  paidAt: string | null;
  rawData: Record<string, unknown>;
}> {
  const midtrans = await midtransRequest(
    `${statusEndpoint}/${encodeURIComponent(midtransOrderId)}/status`,
    {
      method: "GET",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: midtransAuthorization(serverKey),
      },
    },
  );

  const transactionStatus =
    midtrans.transaction_status?.toString().toLowerCase() ?? "";
  const fraudStatus = midtrans.fraud_status?.toString().toLowerCase() ?? "";
  const normalizedStatus = normalizeTransactionStatus(
    transactionStatus,
    fraudStatus,
  );
  const paymentMethod = paymentMethodLabel(
    midtrans.payment_type?.toString().toLowerCase() ?? "",
  );
  const paidAt = normalizedStatus === "paid"
    ? midtrans.settlement_time?.toString() ||
      midtrans.transaction_time?.toString() ||
      new Date().toISOString()
    : null;

  return {
    normalizedStatus,
    transactionStatus,
    fraudStatus,
    paymentMethod,
    paidAt,
    rawData: midtrans,
  };
}

// ── Update order to scheduled after payment ───────────────────────────────────

export async function updateOrderToScheduled(
  admin: SupabaseClient,
  order: OrderRow,
  payment: PaymentRow | null,
  paymentMethod: string,
  paidAt: string | null,
  midtransOrderId: string,
): Promise<void> {
  // Update payment to paid
  await writePayment(
    admin,
    payment,
    {
      order_id: order.id,
      status: "paid",
      provider: "midtrans",
      payment_method: paymentMethod,
      amount: Number(order.total_amount),
      ...(paidAt ? { paid_at: paidAt } : {}),
    },
    {
      provider_order_id: midtransOrderId,
    },
  );
  console.log("PAYMENT UPDATE RESULT", {
    order_id: order.id,
    payment_status: "paid",
  });

  // Update order to scheduled (not 'paid')
  if (["created", "pending_payment"].includes(order.status)) {
    const { error: orderUpdateError } = await admin
      .from("orders")
      .update({ status: "scheduled" })
      .eq("id", order.id);
    if (orderUpdateError) {
      console.error("ORDER STATUS UPDATE ERROR", orderUpdateError);
      throw new HttpError(
        500,
        "order_update_failed",
        "Status pesanan gagal diperbarui.",
      );
    }
    console.log("ORDER UPDATE RESULT", {
      order_id: order.id,
      order_status: "scheduled",
    });
  }
}

// ── Payment write helper ──────────────────────────────────────────────────────

export async function writePayment(
  admin: SupabaseClient,
  payment: PaymentRow | null,
  basePayload: Record<string, unknown>,
  optionalPayload: Record<string, unknown> = {},
): Promise<void> {
  const fullPayload = { ...basePayload, ...optionalPayload };
  const write = async (payload: Record<string, unknown>) => {
    if (payment?.id) {
      return await admin.from("payments").update(payload).eq("id", payment.id);
    }
    return await admin.from("payments").insert(payload);
  };

  const fullResult = await write(fullPayload);
  if (!fullResult.error) return;

  const canRetryWithoutOptionalColumns =
    Object.keys(optionalPayload).length > 0 &&
    (fullResult.error.code === "PGRST204" ||
      fullResult.error.message.includes("Could not find") ||
      fullResult.error.message.includes("schema cache"));

  if (!canRetryWithoutOptionalColumns) {
    console.error("PAYMENT WRITE ERROR", fullResult.error);
    throw new HttpError(
      500,
      "payment_write_failed",
      "Data pembayaran gagal disimpan.",
    );
  }

  console.warn(
    "Optional Midtrans payment columns are unavailable; using base payment schema.",
  );
  const baseResult = await write(basePayload);
  if (baseResult.error) {
    console.error("PAYMENT BASE WRITE ERROR", baseResult.error);
    throw new HttpError(
      500,
      "payment_write_failed",
      "Data pembayaran gagal disimpan.",
    );
  }
}

// ── Midtrans HTTP request helper ──────────────────────────────────────────────

export async function midtransRequest(
  url: string,
  init: RequestInit,
): Promise<Record<string, unknown>> {
  const response = await fetch(url, init);
  const text = await response.text();
  let data: Record<string, unknown> = {};

  if (text) {
    try {
      data = JSON.parse(text) as Record<string, unknown>;
    } catch {
      data = { status_message: text };
    }
  }

  console.log("MIDTRANS RESPONSE", {
    url,
    status: response.status,
    body: data,
  });

  if (!response.ok) {
    console.error("MIDTRANS API ERROR", response.status, data);
    const reason = shortReason(
      data.status_message?.toString() ||
        data.error_messages?.toString() ||
        `HTTP ${response.status}`,
    );
    throw new HttpError(
      502,
      "midtrans_request_failed",
      `Midtrans Sandbox error: ${reason}`,
      data,
    );
  }

  return data;
}

function shortReason(value: string): string {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (!normalized) return "respons tidak diketahui";
  return normalized.slice(0, 180);
}
