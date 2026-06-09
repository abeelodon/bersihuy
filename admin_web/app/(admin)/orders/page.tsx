"use client";

import { useMemo, useState } from "react";
import { Inbox } from "lucide-react";

import { useAdmin } from "@/components/layout/AdminContext";
import { AssignStaffModal } from "@/components/orders/AssignStaffModal";
import { OrderCard } from "@/components/orders/OrderCard";
import { OrderDetailModal } from "@/components/orders/OrderDetailModal";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import type { AdminOrderRow } from "@/types/admin";

const filters = [
  { id: "all", label: "Semua" },
  { id: "unassigned", label: "Belum Ditugaskan" },
  { id: "assigned", label: "Ditugaskan" },
  { id: "in_progress", label: "Dalam Proses" },
  { id: "completed", label: "Selesai" },
  { id: "cancelled", label: "Dibatalkan" },
] as const;

type Filter = (typeof filters)[number]["id"];

export default function OrdersPage() {
  const { data, query } = useAdmin();
  const [filter, setFilter] = useState<Filter>("all");
  const [detail, setDetail] = useState<AdminOrderRow | null>(null);
  const [assign, setAssign] = useState<AdminOrderRow | null>(null);

  const searched = useMemo(() => {
    const needle = query.toLowerCase();
    return data.orders.filter((order) =>
      [
        order.orderNumber,
        order.customerName,
        order.serviceName,
        order.assignedStaffName || "",
        order.address,
      ]
        .join(" ")
        .toLowerCase()
        .includes(needle),
    );
  }, [data.orders, query]);

  const visible = searched.filter((order) => matchesFilter(order, filter));

  return (
    <>
      <div className="mb-4 flex flex-wrap gap-1.5 rounded-2xl border border-[#dce8e5] bg-white p-1.5 shadow-[0_8px_24px_rgba(28,94,88,0.045)]">
        {filters.map((item) => {
          const count = data.orders.filter((order) =>
            matchesFilter(order, item.id),
          ).length;
          return (
            <Button
              key={item.id}
              variant={filter === item.id ? "primary" : "secondary"}
              size="sm"
              onClick={() => setFilter(item.id)}
            >
              {item.label} ({count})
            </Button>
          );
        })}
      </div>

      {visible.length ? (
        <section className="grid gap-3 xl:grid-cols-2">
          {visible.map((order) => (
            <OrderCard
              key={order.id}
              order={order}
              onDetail={() => setDetail(order)}
              onAssign={() => setAssign(order)}
            />
          ))}
        </section>
      ) : (
        <EmptyState
          icon={Inbox}
          title="Tidak ada pesanan"
          description="Belum ada pesanan yang cocok dengan filter dan pencarian."
        />
      )}

      <OrderDetailModal order={detail} onClose={() => setDetail(null)} />
      <AssignStaffModal order={assign} onClose={() => setAssign(null)} />
    </>
  );
}

function matchesFilter(order: AdminOrderRow, filter: Filter) {
  if (filter === "all") return true;
  if (filter === "unassigned") {
    return ["paid", "scheduled"].includes(order.status) && !order.assignedStaffId;
  }
  if (filter === "assigned") return order.effectiveStatus === "assigned";
  if (filter === "in_progress") return order.effectiveStatus === "in_progress";
  if (filter === "completed") return order.effectiveStatus === "completed";
  return order.status === "cancelled";
}
