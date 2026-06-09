"use client";

import { useState } from "react";
import {
  CircleCheckBig,
  CircleX,
  Inbox,
  MessageSquareWarning,
  SearchCheck,
} from "lucide-react";

import { ComplaintCard } from "@/components/complaints/ComplaintCard";
import { ComplaintDetailModal } from "@/components/complaints/ComplaintDetailModal";
import { useAdmin } from "@/components/layout/AdminContext";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatCard } from "@/components/ui/StatCard";
import type { AdminComplaintRow } from "@/types/admin";

const filters = [
  { id: "all", label: "Semua" },
  { id: "open", label: "Open" },
  { id: "in_review", label: "In Review" },
  { id: "resolved", label: "Resolved" },
  { id: "rejected", label: "Rejected" },
] as const;

type Filter = (typeof filters)[number]["id"];

export default function ComplaintsPage() {
  const { data, query } = useAdmin();
  const [filter, setFilter] = useState<Filter>("all");
  const [selected, setSelected] = useState<AdminComplaintRow | null>(null);
  const complaints = data.complaints.filter((item) => {
    const matchesStatus = filter === "all" || item.status === filter;
    const matchesQuery = [
      item.orderNumber,
      item.customerName,
      item.serviceName,
      item.category,
      item.description,
    ]
      .join(" ")
      .toLowerCase()
      .includes(query.toLowerCase());
    return matchesStatus && matchesQuery;
  });

  return (
    <>
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Open"
          value={String(data.complaints.filter((item) => item.status === "open").length)}
          helper="Keluhan baru"
          icon={MessageSquareWarning}
          accent="red"
        />
        <StatCard
          label="In Review"
          value={String(
            data.complaints.filter((item) => item.status === "in_review").length,
          )}
          helper="Sedang ditinjau"
          icon={SearchCheck}
          accent="amber"
        />
        <StatCard
          label="Resolved"
          value={String(
            data.complaints.filter((item) => item.status === "resolved").length,
          )}
          helper="Berhasil diselesaikan"
          icon={CircleCheckBig}
          accent="green"
        />
        <StatCard
          label="Rejected"
          value={String(
            data.complaints.filter((item) => item.status === "rejected").length,
          )}
          helper="Keluhan ditolak"
          icon={CircleX}
          accent="blue"
        />
      </section>

      <div className="my-4 flex flex-wrap gap-1.5 rounded-2xl border border-[#dce8e5] bg-white p-1.5 shadow-[0_8px_24px_rgba(28,94,88,0.045)]">
        {filters.map((item) => (
          <Button
            key={item.id}
            variant={filter === item.id ? "primary" : "secondary"}
            size="sm"
            onClick={() => setFilter(item.id)}
          >
            {item.label} (
            {item.id === "all"
              ? data.complaints.length
              : data.complaints.filter((row) => row.status === item.id).length}
            )
          </Button>
        ))}
      </div>

      {complaints.length ? (
        <section className="grid gap-3 xl:grid-cols-2">
          {complaints.map((complaint) => (
            <ComplaintCard
              key={complaint.id}
              complaint={complaint}
              onDetail={() => setSelected(complaint)}
            />
          ))}
        </section>
      ) : (
        <EmptyState
          icon={Inbox}
          title="Tidak ada keluhan"
          description="Belum ada keluhan pada filter ini. Operasional terlihat bersih."
        />
      )}

      {selected ? (
        <ComplaintDetailModal
          key={selected.id}
          complaint={selected}
          onClose={() => setSelected(null)}
        />
      ) : null}
    </>
  );
}
