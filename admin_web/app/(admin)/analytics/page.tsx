"use client";

import {
  ChartNoAxesCombined,
  CircleDollarSign,
  ClipboardCheck,
  ClipboardList,
  MessageSquareWarning,
  PackageCheck,
  SprayCan,
  Star,
  TrendingUp,
} from "lucide-react";

import { RankList } from "@/components/dashboard/RankList";
import { StatusSummary } from "@/components/dashboard/StatusSummary";
import { TrendChart } from "@/components/dashboard/TrendChart";
import { useAdmin } from "@/components/layout/AdminContext";
import { Badge } from "@/components/ui/Badge";
import { Card } from "@/components/ui/Card";
import { StatCard } from "@/components/ui/StatCard";
import { formatRupiah, initials } from "@/lib/utils/format";

export default function AnalyticsPage() {
  const { data, query } = useAdmin();
  const { summary } = data;
  const staff = [...data.staff]
    .filter((item) => item.fullName.toLowerCase().includes(query.toLowerCase()))
    .sort((a, b) => b.completedTasks - a.completedTasks)
    .slice(0, 6);
  const activeComplaints = data.complaints
    .filter((item) => ["open", "in_review"].includes(item.status))
    .slice(0, 4);

  return (
    <>
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        <StatCard
          label="Total Revenue"
          value={formatRupiah(summary.totalRevenue)}
          helper="Pesanan terbayar"
          icon={CircleDollarSign}
        />
        <StatCard
          label="Total Order"
          value={String(summary.totalOrders)}
          helper="Semua periode"
          icon={ClipboardList}
          accent="blue"
        />
        <StatCard
          label="Average Order Value"
          value={formatRupiah(summary.averageOrderValue)}
          helper="Nilai rata-rata pesanan"
          icon={TrendingUp}
          accent="green"
        />
        <StatCard
          label="Order Selesai"
          value={String(summary.completed)}
          helper="Operasional selesai"
          icon={ClipboardCheck}
          accent="green"
        />
        <StatCard
          label="Rating Rata-rata"
          value={summary.averageRating ? summary.averageRating.toFixed(1) : "-"}
          helper="Dari ulasan customer"
          icon={Star}
          accent="amber"
        />
        <StatCard
          label="Keluhan Terbuka"
          value={String(summary.openComplaints)}
          helper="Butuh tindak lanjut"
          icon={MessageSquareWarning}
          accent="red"
        />
      </section>

      <section className="mt-4 grid gap-4 xl:grid-cols-[1.65fr_1fr]">
        <TrendChart
          points={data.trends}
          mode="revenue"
          title="Revenue Mingguan"
          subtitle="Nilai transaksi tujuh hari terakhir"
        />
        <StatusSummary summary={summary} />
      </section>

      <section className="mt-4 grid gap-4 lg:grid-cols-2">
        <RankList
          title="Kontribusi Layanan"
          subtitle="Peringkat berdasarkan volume"
          items={data.topServices}
          icon={SprayCan}
        />
        <RankList
          title="Kontribusi Produk / Add-on"
          subtitle="Peringkat berdasarkan penjualan"
          items={data.topProducts}
          icon={PackageCheck}
        />
      </section>

      <section className="mt-4 grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
        <Card className="p-4 sm:p-5">
          <h2 className="text-[16px] font-bold text-[#172535]">
            Performa Petugas
          </h2>
          <p className="mt-1 text-xs text-[#74818a]">
            Produktivitas dan kualitas tim operasional
          </p>
          <div className="mt-4 divide-y divide-[#e8f0ee]">
            {staff.map((person) => (
              <div key={person.id} className="flex items-center gap-3 py-3">
                <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-[#45b7ad] text-[10px] font-bold text-white">
                  {initials(person.fullName)}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-bold text-[#253542]">
                    {person.fullName}
                  </p>
                  <p className="mt-1 text-[10px] text-[#7a8790]">
                    {person.completedTasks} selesai dari {person.assignedTasks} tugas
                  </p>
                </div>
                <Badge tone="amber">
                  <Star size={10} className="mr-1" />
                  {person.averageRating ? person.averageRating.toFixed(1) : "-"}
                </Badge>
              </div>
            ))}
            {!staff.length ? (
              <p className="py-10 text-center text-xs text-[#7a8790]">
                Data petugas belum tersedia.
              </p>
            ) : null}
          </div>
        </Card>

        <Card className="p-4 sm:p-5">
          <h2 className="text-[16px] font-bold text-[#172535]">
            Keluhan & Kualitas
          </h2>
          <p className="mt-1 text-xs text-[#74818a]">
            Sinyal kualitas pelayanan terbaru
          </p>
          <div className="mt-4 grid grid-cols-2 gap-2">
            <Metric
              label="Rating Rata-rata"
              value={summary.averageRating ? summary.averageRating.toFixed(1) : "-"}
              icon={Star}
            />
            <Metric
              label="Keluhan Aktif"
              value={String(activeComplaints.length)}
              icon={MessageSquareWarning}
            />
          </div>
          <div className="mt-4 space-y-2">
            {activeComplaints.map((complaint) => (
              <div
                key={complaint.id}
                className="rounded-xl border border-[#e1ebe9] px-3 py-2.5"
              >
                <p className="truncate text-xs font-bold text-[#253542]">
                  {complaint.orderNumber} · {complaint.category}
                </p>
                <p className="mt-1 truncate text-[10px] text-[#7b8890]">
                  {complaint.customerName}
                </p>
              </div>
            ))}
            {!activeComplaints.length ? (
              <div className="rounded-xl bg-[#eaf7ef] px-3 py-5 text-center text-xs text-[#2d7d53]">
                Tidak ada keluhan aktif.
              </div>
            ) : null}
          </div>
        </Card>
      </section>
    </>
  );
}

function Metric({
  label,
  value,
  icon: Icon,
}: {
  label: string;
  value: string;
  icon: typeof ChartNoAxesCombined;
}) {
  return (
    <div className="rounded-xl border border-[#e1ebe9] bg-[#f8fbfa] p-3">
      <Icon size={16} className="text-[#24998f]" />
      <p className="mt-3 text-lg font-bold text-[#172535]">{value}</p>
      <p className="mt-1 text-[9px] text-[#7b8890]">{label}</p>
    </div>
  );
}

