import { ArrowUpRight, MapPin, Star, TimerReset } from "lucide-react";

import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { initials } from "@/lib/utils/format";
import type { AdminStaffProfile } from "@/types/admin";

export function StaffCard({
  staff,
  onDetail,
}: {
  staff: AdminStaffProfile;
  onDetail: () => void;
}) {
  return (
    <Card className="group overflow-hidden p-4 transition duration-200 hover:-translate-y-0.5 hover:border-[#c6ddda] hover:shadow-[0_16px_38px_rgba(28,94,88,0.09)]">
      <div className="flex items-start gap-3">
        <span className="grid size-12 shrink-0 place-items-center rounded-[15px] bg-gradient-to-br from-[#68cec4] to-[#218f86] text-xs font-bold text-white shadow-[0_8px_20px_rgba(36,153,143,0.2)]">
          {initials(staff.fullName)}
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-bold text-[#172535]">
            {staff.fullName}
          </p>
          <p className="mt-1 truncate text-[11px] text-[#728089]">
            {staff.email}
          </p>
        </div>
        <Badge tone={staff.isActive ? "green" : "neutral"}>
          {staff.isActive ? "Siap Bertugas" : "Tidak Aktif"}
        </Badge>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-2">
        <Detail
          icon={MapPin}
          label="Area Layanan"
          value={staff.staffArea || "Belum diatur"}
        />
        <Detail
          icon={TimerReset}
          label="Jadwal Kerja"
          value={staff.staffShift || "Belum diatur"}
        />
      </div>

      <div className="mt-3 grid grid-cols-4 gap-2">
        <Metric label="Ditugaskan" value={staff.assignedTasks} />
        <Metric label="Proses" value={staff.inProgressTasks} />
        <Metric label="Selesai" value={staff.completedTasks} />
        <Metric
          label="Rating"
          value={staff.averageRating ? staff.averageRating.toFixed(1) : "-"}
          icon={<Star size={10} className="text-[#d99a2b]" />}
        />
      </div>

      <Button
        variant="secondary"
        size="sm"
        className="mt-4 w-full"
        icon={<ArrowUpRight size={14} />}
        onClick={onDetail}
      >
        Lihat Detail Petugas
      </Button>
    </Card>
  );
}

function Detail({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof MapPin;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-xl border border-[#e2ecea] bg-[#f8fbfa] p-2.5">
      <div className="flex items-center gap-1.5 text-[#24998f]">
        <Icon size={13} />
        <p className="text-[8px] font-bold uppercase tracking-[0.09em] text-[#8a979f]">
          {label}
        </p>
      </div>
      <p className="mt-1.5 truncate text-[10px] font-semibold text-[#4f606a]">
        {value}
      </p>
    </div>
  );
}

function Metric({
  label,
  value,
  icon,
}: {
  label: string;
  value: number | string;
  icon?: React.ReactNode;
}) {
  return (
    <div className="rounded-xl bg-[#f2f7f6] px-1 py-2.5 text-center">
      <div className="flex items-center justify-center gap-1">
        {icon}
        <span className="text-sm font-bold text-[#172535]">{value}</span>
      </div>
      <p className="mt-1 truncate text-[8px] text-[#7c8991]">{label}</p>
    </div>
  );
}
