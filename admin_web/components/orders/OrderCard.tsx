import {
  CalendarDays,
  MapPin,
  SprayCan,
  UserRoundCog,
  WalletCards,
} from "lucide-react";

import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { formatDate, formatRupiah } from "@/lib/utils/format";
import {
  badgeTone,
  paymentStatusLabel,
  statusLabel,
} from "@/lib/utils/status";
import type { AdminOrderRow } from "@/types/admin";

export function OrderCard({
  order,
  onDetail,
  onAssign,
}: {
  order: AdminOrderRow;
  onDetail: () => void;
  onAssign: () => void;
}) {
  const schedule = [formatDate(order.scheduleDate), order.scheduleTime]
    .filter((value) => value && value !== "-")
    .join(", ");

  return (
    <Card className="group overflow-hidden transition duration-200 hover:-translate-y-0.5 hover:border-[#c6ddda] hover:shadow-[0_16px_38px_rgba(28,94,88,0.09)]">
      <div className="flex items-start gap-3 border-b border-[#e8f0ee] bg-[#fbfdfc] px-4 py-3.5">
        <span className="grid size-10 shrink-0 place-items-center rounded-[13px] bg-[#e5f5f2] text-[#24998f]">
          <SprayCan size={18} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-bold text-[#172535]">
            {order.orderNumber}
          </p>
          <p className="mt-1 truncate text-[11px] text-[#6a7782]">
            {order.customerName} &middot; {order.serviceName}
          </p>
        </div>
        <Badge tone={badgeTone(order.effectiveStatus)}>
          {statusLabel(order.effectiveStatus)}
        </Badge>
      </div>

      <div className="p-4">
        <div className="mb-4 flex flex-wrap gap-1.5">
          <Badge tone={badgeTone(order.paymentStatus)}>
            {paymentStatusLabel(order.paymentStatus)}
          </Badge>
          <Badge tone={order.assignedStaffId ? "teal" : "amber"}>
            {order.assignedStaffName || "Menunggu penugasan"}
          </Badge>
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <Meta
            icon={CalendarDays}
            label="Jadwal"
            value={schedule || "Belum dijadwalkan"}
          />
          <Meta
            icon={WalletCards}
            label="Total"
            value={formatRupiah(order.totalAmount)}
            strong
          />
          <Meta
            icon={MapPin}
            label="Alamat"
            value={order.address}
            className="sm:col-span-2"
          />
        </div>

        {order.addonNames.length ? (
          <div className="mt-3 rounded-xl bg-[#f4f8f7] px-3 py-2 text-[10px] text-[#74818a]">
            Add-on:{" "}
            <span className="font-semibold text-[#53636e]">
              {order.addonNames.join(", ")}
            </span>
          </div>
        ) : null}

        <div className="mt-4 flex flex-wrap gap-2 border-t border-[#e8f0ee] pt-4">
          <Button variant="secondary" size="sm" onClick={onDetail}>
            Lihat Detail
          </Button>
          {!["completed", "cancelled"].includes(order.effectiveStatus) ? (
            <Button
              size="sm"
              icon={<UserRoundCog size={15} />}
              onClick={onAssign}
            >
              {order.assignedStaffId ? "Ubah Petugas" : "Assign Petugas"}
            </Button>
          ) : null}
        </div>
      </div>
    </Card>
  );
}

function Meta({
  icon: Icon,
  label,
  value,
  strong,
  className,
}: {
  icon: typeof CalendarDays;
  label: string;
  value: string;
  strong?: boolean;
  className?: string;
}) {
  return (
    <div className={`flex items-start gap-2.5 ${className || ""}`}>
      <span className="grid size-8 shrink-0 place-items-center rounded-xl bg-[#eef7f5] text-[#24998f]">
        <Icon size={14} />
      </span>
      <div className="min-w-0">
        <p className="text-[9px] font-bold uppercase tracking-[0.1em] text-[#96a2a8]">
          {label}
        </p>
        <p
          className={`mt-1 line-clamp-2 text-[11px] leading-4 ${
            strong ? "font-bold text-[#253542]" : "text-[#61717b]"
          }`}
        >
          {value}
        </p>
      </div>
    </div>
  );
}
