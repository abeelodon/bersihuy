import type { PostgrestError, User } from "@supabase/supabase-js";

import { supabase } from "@/lib/supabase/client";
import type {
  AdminComplaintRow,
  AdminDashboardData,
  AdminDashboardSummary,
  AdminOrderRow,
  AdminProductItem,
  AdminProfile,
  AdminServiceItem,
  AdminStaffProfile,
  AdminTopItem,
  AdminTrendPoint,
} from "@/types/admin";

type Row = Record<string, unknown>;

type RawAdminData = {
  profiles: Row[];
  orders: Row[];
  orderItems: Row[];
  tasks: Row[];
  payments: Row[];
  reviews: Row[];
  complaints: Row[];
  services: Row[];
  products: Row[];
};

export type AdminAccessResult =
  | { profile: AdminProfile; reason: null }
  | { profile: null; reason: "missing-session" | "not-admin" };

function logAndThrow(label: string, error: PostgrestError | Error) {
  console.error(label, error);
  throw new Error(`${label}: ${error.message}`);
}

function asRows(value: unknown): Row[] {
  return Array.isArray(value) ? (value as Row[]) : [];
}

function text(value: unknown, fallback = "") {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function nullableText(value: unknown) {
  const parsed = text(value);
  return parsed || null;
}

function numberValue(value: unknown) {
  if (typeof value === "number") return Number.isFinite(value) ? value : 0;
  if (typeof value === "string") return Number(value) || 0;
  return 0;
}

function boolValue(value: unknown, fallback = true) {
  return typeof value === "boolean" ? value : fallback;
}

function dateKey(value: string | null) {
  if (!value) return "";
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return "";
  return `${parsed.getFullYear()}-${parsed.getMonth()}-${parsed.getDate()}`;
}

function profileName(row: Row | undefined, fallback: string) {
  if (!row) return fallback;
  const name = text(row.full_name);
  if (name) return name;
  const email = text(row.email);
  return email ? email.split("@")[0] : fallback;
}

function effectiveOrderStatus(orderStatus: string, taskStatus: string | null) {
  if (taskStatus === "completed" || orderStatus === "completed") return "completed";
  if (taskStatus === "in_progress" || orderStatus === "in_progress") {
    return "in_progress";
  }
  if (taskStatus === "assigned") return "assigned";
  return orderStatus;
}

function isPaidOrder(order: AdminOrderRow) {
  return (
    order.paymentStatus === "paid" ||
    ["paid", "scheduled", "in_progress", "completed"].includes(order.status)
  );
}

function isAuthSessionMissingError(error: unknown) {
  return (
    error instanceof Error &&
    (error.name === "AuthSessionMissingError" ||
      error.message.toLowerCase().includes("auth session missing"))
  );
}

async function getSessionUser(): Promise<User | null> {
  const {
    data: { session },
    error: sessionError,
  } = await supabase.auth.getSession();

  if (sessionError) {
    if (isAuthSessionMissingError(sessionError)) return null;
    logAndThrow("Gagal memeriksa sesi admin", sessionError);
  }
  if (!session) return null;

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) {
    if (isAuthSessionMissingError(userError)) return null;
    logAndThrow("Gagal memverifikasi pengguna admin", userError);
  }

  return user;
}

async function fetchProfileForUser(user: User): Promise<Row | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, full_name, email, role")
    .eq("id", user.id)
    .maybeSingle();

  if (error) logAndThrow("Gagal memuat profil admin", error);
  return (data as Row | null) ?? null;
}

function toAdminProfile(row: Row, user: User): AdminProfile {
  return {
    id: text(row.id, user.id),
    name: profileName(row, "Admin Bersihuy"),
    email: text(row.email, user.email || "-"),
    role: "admin",
  };
}

async function fetchTable(table: string, orderColumn?: string) {
  let query = supabase.from(table).select("*");
  if (orderColumn) query = query.order(orderColumn, { ascending: false });
  const { data, error } = await query;
  if (error) logAndThrow(`Gagal memuat tabel ${table}`, error);
  return asRows(data);
}

async function fetchRawAdminData(): Promise<RawAdminData> {
  const [
    profiles,
    orders,
    orderItems,
    tasks,
    payments,
    reviews,
    complaints,
    services,
    products,
  ] = await Promise.all([
    fetchTable("profiles"),
    fetchTable("orders", "created_at"),
    fetchTable("order_items"),
    fetchTable("tasks"),
    fetchTable("payments", "created_at"),
    fetchTable("reviews"),
    fetchTable("complaints", "created_at"),
    fetchTable("services"),
    fetchTable("products"),
  ]);

  return {
    profiles,
    orders,
    orderItems,
    tasks,
    payments,
    reviews,
    complaints,
    services,
    products,
  };
}

function buildOrders(raw: RawAdminData): AdminOrderRow[] {
  const profileById = new Map(raw.profiles.map((row) => [text(row.id), row]));
  const itemsByOrder = new Map<string, Row[]>();
  const paymentsByOrder = new Map<string, Row[]>();
  const taskByOrder = new Map<string, Row>();

  for (const item of raw.orderItems) {
    const orderId = text(item.order_id);
    if (!orderId) continue;
    itemsByOrder.set(orderId, [...(itemsByOrder.get(orderId) || []), item]);
  }

  for (const payment of raw.payments) {
    const orderId = text(payment.order_id);
    if (!orderId) continue;
    paymentsByOrder.set(orderId, [
      ...(paymentsByOrder.get(orderId) || []),
      payment,
    ]);
  }

  for (const task of raw.tasks) {
    const orderId = text(task.order_id);
    if (!orderId || taskByOrder.has(orderId)) continue;
    taskByOrder.set(orderId, task);
  }

  return raw.orders.map((row) => {
    const id = text(row.id);
    const items = itemsByOrder.get(id) || [];
    const serviceItem =
      items.find((item) => text(item.item_type) === "service") || items[0];
    const task = taskByOrder.get(id);
    const taskStatus = nullableText(task?.status);
    const staffId = nullableText(task?.staff_id);
    const payments = [...(paymentsByOrder.get(id) || [])].sort((a, b) =>
      text(b.created_at).localeCompare(text(a.created_at)),
    );
    const orderStatus = text(row.status, "created");
    const orderNumber = text(
      row.order_number,
      id ? `ORD-${id.slice(0, 8).toUpperCase()}` : "-",
    );
    const itemNames = items
      .map((item) => text(item.item_name))
      .filter(Boolean);
    const addonNames = items
      .filter((item) => text(item.item_type) !== "service")
      .map((item) => text(item.item_name))
      .filter(Boolean);

    return {
      id,
      orderNumber,
      customerId: text(row.customer_id),
      customerName: profileName(
        profileById.get(text(row.customer_id)),
        "Customer",
      ),
      status: orderStatus,
      effectiveStatus: effectiveOrderStatus(orderStatus, taskStatus),
      scheduleDate: nullableText(row.schedule_date),
      scheduleTime: nullableText(row.schedule_time),
      address: text(row.service_address, "-"),
      customerNote: nullableText(row.customer_note),
      selectedScent: nullableText(row.selected_scent),
      subtotalAmount: numberValue(row.subtotal_amount),
      adminFee: numberValue(row.admin_fee),
      discountAmount: numberValue(row.discount_amount),
      totalAmount: numberValue(row.total_amount),
      serviceName: text(serviceItem?.item_name, "Layanan Bersihuy"),
      itemNames,
      addonNames,
      paymentStatus: nullableText(payments[0]?.status),
      taskId: nullableText(task?.id),
      taskStatus,
      beforePhotoUrl: nullableText(task?.before_photo_url),
      afterPhotoUrl: nullableText(task?.after_photo_url),
      assignedStaffId: staffId,
      assignedStaffName: staffId
        ? profileName(profileById.get(staffId), "Petugas Bersihuy")
        : null,
      createdAt: nullableText(row.created_at),
    };
  });
}

function buildComplaints(
  raw: RawAdminData,
  orders: AdminOrderRow[],
): AdminComplaintRow[] {
  const orderById = new Map(orders.map((order) => [order.id, order]));
  const profileById = new Map(raw.profiles.map((row) => [text(row.id), row]));

  return raw.complaints.map((row) => {
    const orderId = text(row.order_id);
    const order = orderById.get(orderId);
    const handledBy = nullableText(row.handled_by);
    return {
      id: text(row.id),
      orderId,
      orderNumber: order?.orderNumber || "Pesanan",
      customerId: text(row.customer_id, order?.customerId || ""),
      customerName:
        order?.customerName ||
        profileName(profileById.get(text(row.customer_id)), "Customer"),
      serviceName: order?.serviceName || "Layanan Bersihuy",
      assignedStaffId: order?.assignedStaffId || null,
      handledBy,
      handledByName: handledBy
        ? profileName(profileById.get(handledBy), "Admin Bersihuy")
        : null,
      status: text(row.status, "open"),
      category: text(row.category, "Lainnya"),
      description: text(row.description, "-"),
      evidenceUrl: nullableText(row.evidence_url),
      resolutionNote: nullableText(row.resolution_note),
      createdAt: nullableText(row.created_at),
      updatedAt: nullableText(row.updated_at),
    };
  });
}

function buildStaff(
  raw: RawAdminData,
  orders: AdminOrderRow[],
  complaints: AdminComplaintRow[],
): AdminStaffProfile[] {
  return raw.profiles
    .filter((row) => text(row.role) === "staff")
    .map((row) => {
      const id = text(row.id);
      const staffTasks = raw.tasks.filter((task) => text(task.staff_id) === id);
      const ratings = raw.reviews
        .filter((review) => text(review.staff_id) === id)
        .map((review) => numberValue(review.rating))
        .filter((rating) => rating > 0);
      const recentTasks = orders
        .filter((order) => order.assignedStaffId === id)
        .slice(0, 5);

      return {
        id,
        fullName: profileName(row, "Petugas Bersihuy"),
        email: text(row.email, "-"),
        phone:
          nullableText(row.phone) ||
          nullableText(row.phone_number) ||
          nullableText(row.whatsapp),
        avatarUrl: nullableText(row.avatar_url),
        staffArea:
          nullableText(row.staff_area) ||
          nullableText(row.service_area) ||
          nullableText(row.area),
        staffShift:
          nullableText(row.work_schedule) ||
          nullableText(row.staff_shift) ||
          nullableText(row.shift) ||
          nullableText(row.work_shift),
        baseLocation: nullableText(row.base_location),
        workSchedule:
          nullableText(row.work_schedule) ||
          nullableText(row.staff_shift) ||
          nullableText(row.shift) ||
          nullableText(row.work_shift),
        isActive: boolValue(row.is_active),
        assignedTasks: staffTasks.length,
        completedTasks: staffTasks.filter(
          (task) => text(task.status) === "completed",
        ).length,
        inProgressTasks: staffTasks.filter(
          (task) => text(task.status) === "in_progress",
        ).length,
        averageRating: ratings.length
          ? ratings.reduce((total, rating) => total + rating, 0) / ratings.length
          : 0,
        complaintCount: complaints.filter(
          (complaint) => complaint.assignedStaffId === id,
        ).length,
        recentTasks,
      };
    })
    .sort((a, b) => a.fullName.localeCompare(b.fullName));
}

function buildServices(rows: Row[]): AdminServiceItem[] {
  return rows
    .map((row) => ({
      id: text(row.id),
      name: text(row.name, "Layanan Bersihuy"),
      slug: nullableText(row.slug),
      category: text(row.category, "Cleaning"),
      description: text(row.description),
      basePrice: numberValue(row.base_price),
      durationMinutes: numberValue(row.duration_minutes),
      rating: numberValue(row.rating),
      imageAssetPath: nullableText(row.image_asset_path),
      isActive: boolValue(row.is_active),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

function buildProducts(rows: Row[]): AdminProductItem[] {
  return rows
    .map((row) => ({
      id: text(row.id),
      name: text(row.name, "Produk Bersihuy"),
      slug: nullableText(row.slug),
      description: text(row.description),
      price: numberValue(row.price),
      imageAssetPath: nullableText(row.image_asset_path),
      isAddon: boolValue(row.is_addon, false),
      isActive: boolValue(row.is_active),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

function buildTopItems(
  rows: Row[],
  service: boolean,
  catalog: Array<AdminServiceItem | AdminProductItem>,
): AdminTopItem[] {
  const accumulator = new Map<string, AdminTopItem>();
  for (const row of rows) {
    const itemType = text(row.item_type);
    const isService = itemType === "service";
    if (service !== isService) continue;
    const name = text(row.item_name);
    if (!name) continue;
    const key = name.toLowerCase();
    const catalogItem = catalog.find(
      (item) => item.name.toLowerCase() === key,
    );
    const current = accumulator.get(key) || {
      name,
      count: 0,
      revenue: 0,
      imageAssetPath: catalogItem?.imageAssetPath || null,
    };
    current.count += Math.max(1, numberValue(row.quantity));
    current.revenue += numberValue(row.total_price);
    accumulator.set(key, current);
  }
  return [...accumulator.values()]
    .sort((a, b) => b.count - a.count)
    .slice(0, 6);
}

function buildTrends(orders: AdminOrderRow[]): AdminTrendPoint[] {
  const formatter = new Intl.DateTimeFormat("id-ID", { weekday: "short" });
  const now = new Date();
  return Array.from({ length: 7 }, (_, index) => {
    const day = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    day.setDate(day.getDate() - (6 - index));
    const key = dateKey(day.toISOString());
    const matching = orders.filter((order) => dateKey(order.createdAt) === key);
    return {
      label: formatter.format(day),
      date: day.toISOString(),
      orders: matching.length,
      revenue: matching
        .filter(isPaidOrder)
        .reduce((total, order) => total + order.totalAmount, 0),
    };
  });
}

function buildSummary(
  orders: AdminOrderRow[],
  complaints: AdminComplaintRow[],
  reviews: Row[],
): AdminDashboardSummary {
  const now = new Date();
  const paidOrders = orders.filter(isPaidOrder);
  const totalRevenue = paidOrders.reduce(
    (total, order) => total + order.totalAmount,
    0,
  );
  const ratings = reviews
    .map((review) => numberValue(review.rating))
    .filter((rating) => rating > 0);

  return {
    totalOrders: orders.length,
    todayOrders: orders.filter(
      (order) => dateKey(order.createdAt) === dateKey(now.toISOString()),
    ).length,
    waitingAssignment: orders.filter(
      (order) =>
        ["paid", "scheduled"].includes(order.status) &&
        !order.assignedStaffId,
    ).length,
    assigned: orders.filter(
      (order) => order.effectiveStatus === "assigned",
    ).length,
    inProgress: orders.filter(
      (order) => order.effectiveStatus === "in_progress",
    ).length,
    completed: orders.filter(
      (order) => order.effectiveStatus === "completed",
    ).length,
    openComplaints: complaints.filter((item) => item.status === "open").length,
    totalRevenue,
    monthlyRevenue: paidOrders
      .filter((order) => {
        if (!order.createdAt) return false;
        const created = new Date(order.createdAt);
        return (
          created.getFullYear() === now.getFullYear() &&
          created.getMonth() === now.getMonth()
        );
      })
      .reduce((total, order) => total + order.totalAmount, 0),
    averageOrderValue: paidOrders.length ? totalRevenue / paidOrders.length : 0,
    averageRating: ratings.length
      ? ratings.reduce((total, rating) => total + rating, 0) / ratings.length
      : 0,
  };
}

export async function checkCurrentAdminAccess(): Promise<AdminAccessResult> {
  const user = await getSessionUser();
  if (!user) return { profile: null, reason: "missing-session" };

  const row = await fetchProfileForUser(user);
  if (!row || text(row.role) !== "admin") {
    await supabase.auth.signOut();
    return { profile: null, reason: "not-admin" };
  }

  return { profile: toAdminProfile(row, user), reason: null };
}

export async function getCurrentAdminProfile(): Promise<AdminProfile | null> {
  const access = await checkCurrentAdminAccess();
  return access.profile;
}

export async function requireAdminProfile(): Promise<AdminProfile | null> {
  const access = await checkCurrentAdminAccess();
  if (access.reason === "not-admin") {
    throw new Error("Akun ini bukan admin.");
  }
  return access.profile;
}

export async function getOrders() {
  return buildOrders(await fetchRawAdminData());
}

export async function getStaffProfiles() {
  const raw = await fetchRawAdminData();
  const orders = buildOrders(raw);
  const complaints = buildComplaints(raw, orders);
  return buildStaff(raw, orders, complaints);
}

export async function getServices() {
  return buildServices(await fetchTable("services"));
}

export async function getProducts() {
  return buildProducts(await fetchTable("products"));
}

export async function getTasks() {
  return fetchTable("tasks");
}

export async function getPayments() {
  return fetchTable("payments", "created_at");
}

export async function getReviews() {
  return fetchTable("reviews");
}

export async function getComplaints() {
  const raw = await fetchRawAdminData();
  return buildComplaints(raw, buildOrders(raw));
}

export async function loadDashboardData(
  profile: AdminProfile,
): Promise<AdminDashboardData> {
  const raw = await fetchRawAdminData();
  const orders = buildOrders(raw);
  const complaints = buildComplaints(raw, orders);
  const services = buildServices(raw.services);
  const products = buildProducts(raw.products);

  return {
    profile,
    orders,
    complaints,
    staff: buildStaff(raw, orders, complaints),
    services,
    products,
    topServices: buildTopItems(raw.orderItems, true, services),
    topProducts: buildTopItems(raw.orderItems, false, products),
    trends: buildTrends(orders),
    summary: buildSummary(orders, complaints, raw.reviews),
  };
}

export async function assignStaffToOrder(
  order: AdminOrderRow,
  staff: AdminStaffProfile,
  currentAdminId: string,
) {
  if (!currentAdminId.trim()) throw new Error("Admin belum login.");
  if (!order.id.trim()) throw new Error("Order ID tidak boleh kosong.");
  if (!staff.id.trim()) throw new Error("Staff ID tidak boleh kosong.");

  const { data: existingTask, error: taskError } = await supabase
    .from("tasks")
    .select("id, status")
    .eq("order_id", order.id)
    .maybeSingle();
  if (taskError) logAndThrow("Gagal memeriksa task pesanan", taskError);

  const oldStatus = existingTask ? text((existingTask as Row).status) : null;
  let taskId = existingTask ? text((existingTask as Row).id) : "";
  const assignedAt = new Date().toISOString();

  if (existingTask) {
    const nextStatus = oldStatus === "completed" ? "completed" : "assigned";
    const { error } = await supabase
      .from("tasks")
      .update({
        staff_id: staff.id,
        status: nextStatus,
        assigned_at: assignedAt,
      })
      .eq("id", taskId);
    if (error) logAndThrow("Gagal mengubah petugas", error);
  } else {
    const { data, error } = await supabase
      .from("tasks")
      .insert({
        order_id: order.id,
        staff_id: staff.id,
        status: "assigned",
        assigned_at: assignedAt,
      })
      .select("id")
      .single();
    if (error) logAndThrow("Gagal membuat task petugas", error);
    taskId = text((data as Row).id);
  }

  if (!taskId) throw new Error("Task ID tidak tersedia setelah assignment.");

  if (["paid", "scheduled"].includes(order.status)) {
    const { error } = await supabase
      .from("orders")
      .update({ status: "scheduled" })
      .eq("id", order.id);
    if (error) logAndThrow("Gagal memperbarui status pesanan", error);
  }

  const { error: historyError } = await supabase
    .from("task_status_history")
    .insert({
      task_id: taskId,
      old_status: oldStatus,
      new_status: "assigned",
      changed_by: currentAdminId,
      note: "Admin menugaskan petugas",
    });
  if (historyError) logAndThrow("Gagal menyimpan riwayat task", historyError);
}

export async function updateComplaint(
  complaint: AdminComplaintRow,
  status: string,
  resolutionNote: string,
  currentAdminId: string,
) {
  if (!currentAdminId.trim()) throw new Error("Admin belum login.");
  if (!complaint.id.trim()) throw new Error("Complaint ID tidak boleh kosong.");

  const { error } = await supabase
    .from("complaints")
    .update({
      status,
      resolution_note: resolutionNote.trim() || null,
      handled_by: currentAdminId,
    })
    .eq("id", complaint.id);
  if (error) logAndThrow("Gagal memperbarui keluhan", error);
}
