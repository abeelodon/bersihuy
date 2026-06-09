"use client";

import { Badge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { formatDate, formatRupiah } from "@/lib/utils/format";
import {
  badgeTone,
  paymentStatusLabel,
  statusLabel,
} from "@/lib/utils/status";
import type { AdminOrderRow } from "@/types/admin";

export function OrderDetailModal({
  order,
  onClose,
}: {
  order: AdminOrderRow | null;
  onClose: () => void;
}) {
  if (!order) return null;

  return (
    <Modal
      open
      onClose={onClose}
      title="Detail Pesanan"
      subtitle={order.orderNumber}
      size="lg"
    >
      <div className="mb-5 flex flex-wrap gap-2">
        <Badge tone={badgeTone(order.effectiveStatus)}>
          {statusLabel(order.effectiveStatus)}
        </Badge>
        <Badge tone={badgeTone(order.paymentStatus)}>
          {paymentStatusLabel(order.paymentStatus)}
        </Badge>
        <Badge tone={order.assignedStaffId ? "teal" : "amber"}>
          {order.assignedStaffName || "Menunggu penugasan"}
        </Badge>
      </div>

      <div className="grid gap-x-6 md:grid-cols-2">
        <Info label="Customer" value={order.customerName} />
        <Info label="Layanan" value={order.serviceName} />
        <Info
          label="Add-on / Produk"
          value={order.addonNames.length ? order.addonNames.join(", ") : "-"}
        />
        <Info
          label="Jadwal"
          value={`${formatDate(order.scheduleDate)}${order.scheduleTime ? `, ${order.scheduleTime}` : ""}`}
        />
        <Info label="Alamat" value={order.address} wide />
        <Info label="Catatan customer" value={order.customerNote || "-"} wide />
        <Info label="Aroma pilihan" value={order.selectedScent || "-"} />
        <Info label="Task status" value={statusLabel(order.taskStatus)} />
      </div>

      <div className="mt-2 rounded-2xl border border-[#dce9e7] bg-[#f7fbfa] p-4">
        <h3 className="text-xs font-bold text-[#253542]">Rincian Pembayaran</h3>
        <div className="mt-3 space-y-2">
          <Money label="Subtotal" value={order.subtotalAmount} />
          <Money label="Biaya admin" value={order.adminFee} />
          <Money label="Diskon" value={-order.discountAmount} />
          <div className="border-t border-[#dce9e7] pt-2">
            <Money label="Total" value={order.totalAmount} strong />
          </div>
        </div>
      </div>

      <div className="mt-4">
        <h3 className="text-xs font-bold text-[#253542]">Bukti Pekerjaan</h3>
        <div className="mt-3 grid grid-cols-2 gap-3">
          <ProofImage label="Sebelum" url={order.beforePhotoUrl} />
          <ProofImage label="Sesudah" url={order.afterPhotoUrl} />
        </div>
      </div>
    </Modal>
  );
}

function ProofImage({ label, url }: { label: string; url: string | null }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-[#dce9e7] bg-[#f7fbfa]">
      {url ? (
        <a
          href={url}
          target="_blank"
          rel="noreferrer"
          className="block h-36 bg-cover bg-center"
          style={{ backgroundImage: `url("${url}")` }}
          aria-label={`Lihat bukti ${label.toLowerCase()}`}
        />
      ) : (
        <div className="grid h-36 place-items-center px-3 text-center text-xs text-[#7a8790]">
          Bukti belum diunggah.
        </div>
      )}
      <p className="border-t border-[#dce9e7] px-3 py-2 text-center text-[10px] font-bold text-[#253542]">
        {label}
      </p>
    </div>
  );
}

function Info({
  label,
  value,
  wide,
}: {
  label: string;
  value: string;
  wide?: boolean;
}) {
  return (
    <div className={`mb-4 ${wide ? "md:col-span-2" : ""}`}>
      <p className="text-[10px] font-bold uppercase tracking-[0.1em] text-[#8a979f]">
        {label}
      </p>
      <p className="mt-1.5 text-[13px] font-semibold leading-6 text-[#253542]">
        {value}
      </p>
    </div>
  );
}

function Money({
  label,
  value,
  strong,
}: {
  label: string;
  value: number;
  strong?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-4">
      <span className={`text-xs ${strong ? "font-bold" : "text-[#6a7782]"}`}>
        {label}
      </span>
      <span className={`text-xs ${strong ? "font-bold text-[#172535]" : ""}`}>
        {formatRupiah(value)}
      </span>
    </div>
  );
}
