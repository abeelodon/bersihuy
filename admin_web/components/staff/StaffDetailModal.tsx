"use client";

import { Badge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { initials } from "@/lib/utils/format";
import { statusLabel } from "@/lib/utils/status";
import type { AdminStaffProfile } from "@/types/admin";

export function StaffDetailModal({
  staff,
  onClose,
}: {
  staff: AdminStaffProfile | null;
  onClose: () => void;
}) {
  if (!staff) return null;

  return (
    <Modal open onClose={onClose} title="Detail Petugas" subtitle={staff.fullName}>
      <div className="flex items-center gap-3">
        <span className="grid size-14 place-items-center rounded-2xl bg-gradient-to-br from-[#65c9bf] to-[#24998f] text-base font-bold text-white">
          {initials(staff.fullName)}
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-base font-bold text-[#172535]">
            {staff.fullName}
          </p>
          <p className="mt-1 truncate text-xs text-[#6f7d86]">{staff.email}</p>
          <div className="mt-2">
            <Badge tone={staff.isActive ? "green" : "neutral"}>
              {staff.isActive ? "Siap Bertugas" : "Tidak Aktif"}
            </Badge>
          </div>
        </div>
      </div>

      <div className="mt-5 grid gap-3 rounded-2xl border border-[#dce9e7] bg-[#f8fbfa] p-4 sm:grid-cols-2">
        <Info label="Telepon" value={staff.phone || "-"} />
        <Info label="Area Layanan" value={staff.staffArea || "-"} />
        <Info
          label="Jadwal Kerja"
          value={staff.workSchedule || staff.staffShift || "-"}
        />
        <Info label="Lokasi Base" value={staff.baseLocation || "-"} />
        <Info
          label="Rating Rata-rata"
          value={staff.averageRating ? staff.averageRating.toFixed(1) : "-"}
        />
      </div>

      <div className="mt-4 grid grid-cols-2 gap-2 sm:grid-cols-4">
        <Metric label="Ditugaskan" value={staff.assignedTasks} />
        <Metric label="Dalam Proses" value={staff.inProgressTasks} />
        <Metric label="Selesai" value={staff.completedTasks} />
        <Metric label="Keluhan" value={staff.complaintCount} />
      </div>

      <h3 className="mb-2 mt-5 text-xs font-bold text-[#253542]">Tugas Terbaru</h3>
      <div className="space-y-2">
        {staff.recentTasks.length ? (
          staff.recentTasks.map((order) => (
            <div
              key={order.id}
              className="flex items-center gap-3 rounded-xl border border-[#e0ebe9] px-3 py-2.5"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-bold text-[#253542]">
                  {order.orderNumber}
                </p>
                <p className="mt-1 truncate text-[10px] text-[#7a8790]">
                  {order.serviceName} · {order.customerName}
                </p>
              </div>
              <Badge tone="neutral">{statusLabel(order.effectiveStatus)}</Badge>
            </div>
          ))
        ) : (
          <p className="rounded-xl bg-[#f7faf9] px-3 py-5 text-center text-xs text-[#7a8790]">
            Belum ada tugas untuk petugas ini.
          </p>
        )}
      </div>
    </Modal>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[10px] uppercase tracking-[0.1em] text-[#8c989f]">
        {label}
      </p>
      <p className="mt-1 text-xs font-bold text-[#253542]">{value}</p>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-[#e1ebe9] p-3 text-center">
      <p className="text-lg font-bold text-[#172535]">{value}</p>
      <p className="mt-1 text-[9px] text-[#7a8790]">{label}</p>
    </div>
  );
}
