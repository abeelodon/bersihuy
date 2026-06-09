"use client";

import { useState } from "react";
import Link from "next/link";
import {
  AlertCircle,
  ArrowRight,
  CalendarCheck2,
  CircleDollarSign,
  ClipboardCheck,
  ClipboardList,
  Clock3,
  MessageSquareWarning,
  PackageCheck,
  ShieldAlert,
  SprayCan,
  UserRoundCheck,
} from "lucide-react";

import { RankList } from "@/components/dashboard/RankList";
import { StatusSummary } from "@/components/dashboard/StatusSummary";
import { TrendChart } from "@/components/dashboard/TrendChart";
import { useAdmin } from "@/components/layout/AdminContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { StatCard } from "@/components/ui/StatCard";
import { OrderDetailModal } from "@/components/orders/OrderDetailModal";
import { cn } from "@/lib/utils/cn";
import { formatDate, formatRupiah } from "@/lib/utils/format";
import {
  badgeTone,
  complaintStatusLabel,
  statusLabel,
} from "@/lib/utils/status";
import type { AdminOrderRow } from "@/types/admin";

export default function DashboardPage() {
  const { data, query } = useAdmin();
  const [selectedOrder, setSelectedOrder] = useState<AdminOrderRow | null>(null);
  const { summary } = data;
  const needle = query.toLowerCase();
  const recentOrders = data.orders
    .filter((order) =>
      [order.orderNumber, order.customerName, order.serviceName]
        .join(" ")
        .toLowerCase()
        .includes(needle),
    )
    .slice(0, 6);
  const recentComplaints = data.complaints
    .filter((item) =>
      [item.orderNumber, item.customerName, item.category]
        .join(" ")
        .toLowerCase()
        .includes(needle),
    )
    .slice(0, 4);

  return (
    <>
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Total Pesanan"
          value={String(summary.totalOrders)}
          helper="Seluruh pesanan"
          icon={ClipboardList}
        />
        <StatCard
          label="Pesanan Hari Ini"
          value={String(summary.todayOrders)}
          helper="Aktivitas hari ini"
          icon={CalendarCheck2}
          accent="blue"
        />
        <StatCard
          label="Menunggu Penugasan"
          value={String(summary.waitingAssignment)}
          helper="Perlu ditindaklanjuti"
          icon={Clock3}
          accent="amber"
        />
        <StatCard
          label="Dalam Proses"
          value={String(summary.inProgress)}
          helper="Sedang dikerjakan"
          icon={SprayCan}
          accent="blue"
        />
        <StatCard
          label="Selesai"
          value={String(summary.completed)}
          helper="Tugas selesai"
          icon={PackageCheck}
          accent="green"
        />
        <StatCard
          label="Keluhan Terbuka"
          value={String(summary.openComplaints)}
          helper="Perlu ditinjau"
          icon={ShieldAlert}
          accent="red"
        />
        <StatCard
          label="Revenue Bulan Ini"
          value={formatRupiah(summary.monthlyRevenue)}
          helper="Pembayaran tercatat"
          icon={CircleDollarSign}
        />
        <StatCard
          label="Petugas Aktif"
          value={String(data.staff.filter((staff) => staff.isActive).length)}
          helper="Siap bertugas"
          icon={ClipboardCheck}
          accent="green"
        />
      </section>

      <section className="mt-4 grid gap-4 xl:grid-cols-[1.65fr_1fr]">
        <TrendChart
          points={data.trends}
          title="Tren Pesanan"
          subtitle="Volume pesanan tujuh hari terakhir"
        />
        <StatusSummary summary={summary} />
      </section>

      <section className="mt-4 grid gap-4 xl:grid-cols-[1fr_1fr_0.86fr]">
        <RankList
          title="Layanan Terlaris"
          subtitle="Berdasarkan item pesanan"
          items={data.topServices}
          icon={SprayCan}
        />
        <RankList
          title="Produk / Add-on Terlaris"
          subtitle="Produk tambahan paling sering dipilih"
          items={data.topProducts}
          icon={PackageCheck}
        />
        <Card className="overflow-hidden">
          <div className="border-b border-[#e8f0ee] px-4 py-4 sm:px-5">
            <h2 className="text-[16px] font-bold text-[#172535]">
              Prioritas Hari Ini
            </h2>
            <p className="mt-1 text-xs text-[#74818a]">
              Fokus operasional yang perlu dijaga
            </p>
          </div>
          <div className="space-y-2.5 p-4 sm:p-5">
            <FocusItem
              href="/orders"
              icon={UserRoundCheck}
              label="Penugasan petugas"
              detail={`${summary.waitingAssignment} pesanan menunggu`}
              tone="amber"
            />
            <FocusItem
              href="/complaints"
              icon={MessageSquareWarning}
              label="Tinjau keluhan"
              detail={`${summary.openComplaints} keluhan terbuka`}
              tone="red"
            />
            <FocusItem
              href="/orders"
              icon={SprayCan}
              label="Pantau pekerjaan"
              detail={`${summary.inProgress} sedang diproses`}
              tone="teal"
            />
          </div>
          <div className="mx-4 mb-4 rounded-2xl bg-gradient-to-br from-[#edf9f7] to-[#e2f3f0] p-4 sm:mx-5 sm:mb-5">
            <div className="flex items-start gap-3">
              <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-white text-[#24998f] shadow-sm">
                <AlertCircle size={17} />
              </span>
              <div>
                <p className="text-xs font-bold text-[#25433f]">
                  Kondisi operasional
                </p>
                <p className="mt-1 text-[10px] leading-5 text-[#6c817e]">
                  {summary.waitingAssignment || summary.openComplaints
                    ? "Ada item yang membutuhkan perhatian admin."
                    : "Semua prioritas utama dalam kondisi terkendali."}
                </p>
              </div>
            </div>
          </div>
        </Card>
      </section>

      <section className="mt-4 grid gap-4 xl:grid-cols-[1.45fr_0.8fr]">
        <Card className="overflow-hidden">
          <div className="flex items-start gap-3 border-b border-[#e8f0ee] px-4 py-4 sm:px-5">
            <div className="min-w-0 flex-1">
              <h2 className="text-[16px] font-bold text-[#172535]">
                Pesanan Terbaru
              </h2>
              <p className="mt-1 text-xs text-[#74818a]">
                Aktivitas customer paling baru
              </p>
            </div>
            <Link
              href="/orders"
              className="inline-flex items-center gap-1 text-[11px] font-bold text-[#238d84] hover:text-[#176f69]"
            >
              Lihat semua <ArrowRight size={13} />
            </Link>
          </div>
          <div className="divide-y divide-[#e8f0ee] px-4 sm:px-5">
            {recentOrders.map((order) => (
              <div
                key={order.id}
                className="flex flex-col gap-3 py-3.5 sm:flex-row sm:items-center"
              >
                <span className="grid size-10 shrink-0 place-items-center rounded-[13px] bg-[#e8f6f3] text-[#24998f]">
                  <ClipboardList size={18} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-bold text-[#253542]">
                    {order.orderNumber} &middot; {order.customerName}
                  </p>
                  <p className="mt-1 truncate text-[10px] text-[#76838b]">
                    {order.serviceName} &middot;{" "}
                    {formatDate(order.scheduleDate)}
                  </p>
                </div>
                <Badge tone={badgeTone(order.effectiveStatus)}>
                  {statusLabel(order.effectiveStatus)}
                </Badge>
                <p className="min-w-24 text-xs font-bold text-[#253542]">
                  {formatRupiah(order.totalAmount)}
                </p>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedOrder(order)}
                >
                  Detail
                </Button>
              </div>
            ))}
            {!recentOrders.length ? (
              <p className="py-10 text-center text-xs text-[#78858d]">
                Belum ada pesanan terbaru.
              </p>
            ) : null}
          </div>
        </Card>

        <Card className="overflow-hidden">
          <div className="flex items-start gap-3 border-b border-[#e8f0ee] px-4 py-4 sm:px-5">
            <div className="min-w-0 flex-1">
              <h2 className="text-[16px] font-bold text-[#172535]">
                Keluhan Terbaru
              </h2>
              <p className="mt-1 text-xs text-[#74818a]">
                Sinyal kualitas layanan
              </p>
            </div>
            <Link
              href="/complaints"
              className="inline-flex items-center gap-1 text-[11px] font-bold text-[#238d84]"
            >
              Lihat <ArrowRight size={13} />
            </Link>
          </div>
          <div className="space-y-2.5 p-4 sm:p-5">
            {recentComplaints.map((complaint) => (
              <div
                key={complaint.id}
                className="rounded-2xl border border-[#e1ebe9] bg-[#fbfdfc] p-3.5"
              >
                <div className="flex items-start gap-3">
                  <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-[#ffefec] text-[#bc5e52]">
                    <MessageSquareWarning size={16} />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs font-bold text-[#253542]">
                      {complaint.orderNumber}
                    </p>
                    <p className="mt-1 truncate text-[10px] text-[#7a8790]">
                      {complaint.category} &middot; {complaint.customerName}
                    </p>
                  </div>
                  <Badge tone={badgeTone(complaint.status)}>
                    {complaintStatusLabel(complaint.status)}
                  </Badge>
                </div>
              </div>
            ))}
            {!recentComplaints.length ? (
              <div className="rounded-2xl border border-[#cde7d5] bg-[#edf8f1] px-4 py-8 text-center">
                <ClipboardCheck
                  size={24}
                  className="mx-auto text-[#49a572]"
                />
                <p className="mt-2 text-xs font-semibold text-[#377553]">
                  Tidak ada keluhan terbaru.
                </p>
              </div>
            ) : null}
          </div>
        </Card>
      </section>

      <OrderDetailModal
        order={selectedOrder}
        onClose={() => setSelectedOrder(null)}
      />
    </>
  );
}

const focusTones = {
  amber: {
    wrap: "border-[#f0dfbd] bg-[#fff9ed]",
    icon: "bg-[#fff0cf] text-[#b27b20]",
  },
  red: {
    wrap: "border-[#efd7d2] bg-[#fff7f5]",
    icon: "bg-[#ffebe7] text-[#bd5c50]",
  },
  teal: {
    wrap: "border-[#d3e9e5] bg-[#f5fbfa]",
    icon: "bg-[#e3f5f2] text-[#258d84]",
  },
};

function FocusItem({
  href,
  icon: Icon,
  label,
  detail,
  tone,
}: {
  href: string;
  icon: typeof SprayCan;
  label: string;
  detail: string;
  tone: keyof typeof focusTones;
}) {
  const styles = focusTones[tone];
  return (
    <Link
      href={href}
      className={cn(
        "group flex items-center gap-3 rounded-2xl border p-3 transition hover:-translate-y-0.5 hover:shadow-sm",
        styles.wrap,
      )}
    >
      <span
        className={cn(
          "grid size-9 shrink-0 place-items-center rounded-xl",
          styles.icon,
        )}
      >
        <Icon size={16} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-bold text-[#293d48]">{label}</p>
        <p className="mt-0.5 truncate text-[10px] text-[#7a8790]">{detail}</p>
      </div>
      <ArrowRight
        size={14}
        className="text-[#95a2a8] transition group-hover:translate-x-0.5"
      />
    </Link>
  );
}
