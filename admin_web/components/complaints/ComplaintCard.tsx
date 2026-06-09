import { CalendarDays, MessageSquareWarning, UserRound } from "lucide-react";

import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { formatDate } from "@/lib/utils/format";
import { badgeTone, complaintStatusLabel } from "@/lib/utils/status";
import type { AdminComplaintRow } from "@/types/admin";

export function ComplaintCard({
  complaint,
  onDetail,
}: {
  complaint: AdminComplaintRow;
  onDetail: () => void;
}) {
  return (
    <Card className="group overflow-hidden p-4 transition duration-200 hover:-translate-y-0.5 hover:border-[#d9cbc8] hover:shadow-[0_16px_38px_rgba(110,69,62,0.07)]">
      <div className="flex items-start gap-3">
        <span className="grid size-11 shrink-0 place-items-center rounded-[14px] bg-[#ffefec] text-[#bd5c50]">
          <MessageSquareWarning size={19} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-bold text-[#172535]">
            {complaint.orderNumber}
          </p>
          <p className="mt-1 truncate text-[11px] text-[#74818a]">
            {complaint.serviceName}
          </p>
        </div>
        <Badge tone={badgeTone(complaint.status)}>
          {complaintStatusLabel(complaint.status)}
        </Badge>
      </div>

      <div className="mt-4 flex flex-wrap items-center gap-2">
        <Badge tone="neutral">{complaint.category}</Badge>
        <span className="inline-flex items-center gap-1 text-[10px] text-[#7b8890]">
          <UserRound size={12} />
          {complaint.customerName}
        </span>
      </div>

      <p className="mt-3 line-clamp-3 rounded-xl bg-[#f8faf9] px-3 py-2.5 text-xs leading-5 text-[#53636e]">
        {complaint.description}
      </p>

      <div className="mt-4 flex items-center gap-2 border-t border-[#e8f0ee] pt-4">
        <CalendarDays className="text-[#7c8991]" size={14} />
        <span className="flex-1 text-[10px] text-[#7c8991]">
          {formatDate(complaint.createdAt)}
        </span>
        <Button variant="secondary" size="sm" onClick={onDetail}>
          Detail / Update
        </Button>
      </div>
    </Card>
  );
}
