"use client";

import { useState } from "react";
import { CheckCircle2, LoaderCircle, MapPin, UserRoundCog } from "lucide-react";

import { useAdmin } from "@/components/layout/AdminContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { assignStaffToOrder } from "@/lib/supabase/adminRepository";
import { cn } from "@/lib/utils/cn";
import { initials } from "@/lib/utils/format";
import type { AdminOrderRow, AdminStaffProfile } from "@/types/admin";

export function AssignStaffModal({
  order,
  onClose,
}: {
  order: AdminOrderRow | null;
  onClose: () => void;
}) {
  const { data, reload, showToast } = useAdmin();
  const [selected, setSelected] = useState<AdminStaffProfile | null>(null);
  const [loading, setLoading] = useState(false);

  if (!order) return null;

  async function submit() {
    if (!selected) return;
    setLoading(true);
    try {
      await assignStaffToOrder(order!, selected, data.profile.id);
      await reload();
      showToast("Petugas berhasil ditugaskan.");
      onClose();
    } catch (caught) {
      const message =
        caught instanceof Error ? caught.message : "Assign petugas gagal.";
      showToast(message, "error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      open
      onClose={loading ? () => undefined : onClose}
      title={order.assignedStaffId ? "Ubah Petugas" : "Assign Petugas"}
      subtitle={`${order.orderNumber} · ${order.serviceName}`}
      size="xl"
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={loading}>
            Batal
          </Button>
          <Button
            onClick={() => void submit()}
            disabled={!selected || loading}
            icon={
              loading ? (
                <LoaderCircle className="animate-spin" size={16} />
              ) : (
                <UserRoundCog size={16} />
              )
            }
          >
            {order.assignedStaffId ? "Ubah Petugas" : "Assign Petugas"}
          </Button>
        </>
      }
    >
      <div className="mb-5 rounded-2xl border border-[#dce9e7] bg-[#f5faf9] p-4">
        <p className="text-xs font-bold text-[#172535]">{order.customerName}</p>
        <p className="mt-1 text-xs text-[#687780]">{order.address}</p>
      </div>

      <p className="mb-3 text-xs font-bold text-[#253542]">
        Pilih petugas yang akan ditugaskan
      </p>
      <div className="grid max-h-[440px] gap-2.5 overflow-y-auto pr-1 md:grid-cols-2">
        {data.staff.map((staff) => {
          const active = selected?.id === staff.id;
          return (
            <button
              key={staff.id}
              type="button"
              onClick={() => setSelected(staff)}
              className={cn(
                "focus-ring rounded-2xl border p-3.5 text-left transition",
                active
                  ? "border-[#24998f] bg-[#eaf7f5]"
                  : "border-[#dce9e7] bg-white hover:border-[#a9d2cd]",
              )}
            >
              <div className="flex items-start gap-3">
                <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-[#45b7ad] text-xs font-bold text-white">
                  {initials(staff.fullName)}
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-start gap-2">
                    <p className="min-w-0 flex-1 truncate text-xs font-bold text-[#172535]">
                      {staff.fullName}
                    </p>
                    {active ? (
                      <CheckCircle2 className="text-[#24998f]" size={18} />
                    ) : null}
                  </div>
                  <p className="mt-1 truncate text-[10px] text-[#7a8790]">
                    {staff.email}
                    {staff.phone ? ` · ${staff.phone}` : ""}
                  </p>
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    <Badge tone={staff.isActive ? "green" : "neutral"}>
                      {staff.isActive ? "Siap Bertugas" : "Tidak Aktif"}
                    </Badge>
                    <Badge tone="neutral">
                      <MapPin size={10} className="mr-1" />
                      {staff.staffArea || "Area belum diatur"}
                    </Badge>
                    <Badge tone="neutral">
                      {staff.staffShift || "Shift belum diatur"}
                    </Badge>
                  </div>
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </Modal>
  );
}

