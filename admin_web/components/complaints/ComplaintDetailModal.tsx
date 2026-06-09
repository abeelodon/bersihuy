"use client";

import { useState } from "react";
import { ExternalLink, LoaderCircle, Save } from "lucide-react";

import { useAdmin } from "@/components/layout/AdminContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { updateComplaint } from "@/lib/supabase/adminRepository";
import { formatDateTime } from "@/lib/utils/format";
import { badgeTone, complaintStatusLabel } from "@/lib/utils/status";
import type { AdminComplaintRow } from "@/types/admin";

export function ComplaintDetailModal({
  complaint,
  onClose,
}: {
  complaint: AdminComplaintRow;
  onClose: () => void;
}) {
  const { data, reload, showToast } = useAdmin();
  const [status, setStatus] = useState(complaint.status);
  const [note, setNote] = useState(complaint.resolutionNote || "");
  const [loading, setLoading] = useState(false);

  async function submit() {
    setLoading(true);
    try {
      await updateComplaint(complaint, status, note, data.profile.id);
      await reload();
      showToast("Keluhan berhasil diperbarui.");
      onClose();
    } catch (caught) {
      showToast(
        caught instanceof Error ? caught.message : "Update keluhan gagal.",
        "error",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      open
      onClose={loading ? () => undefined : onClose}
      title="Detail Keluhan"
      subtitle={complaint.orderNumber}
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={loading}>
            Batal
          </Button>
          <Button
            onClick={() => void submit()}
            disabled={loading}
            icon={
              loading ? (
                <LoaderCircle className="animate-spin" size={16} />
              ) : (
                <Save size={16} />
              )
            }
          >
            Simpan Perubahan
          </Button>
        </>
      }
    >
      <div className="flex flex-wrap gap-2">
        <Badge tone={badgeTone(complaint.status)}>
          {complaintStatusLabel(complaint.status)}
        </Badge>
        <Badge tone="neutral">{complaint.category}</Badge>
      </div>

      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <Info label="Customer" value={complaint.customerName} />
        <Info label="Layanan" value={complaint.serviceName} />
        <Info label="Tanggal" value={formatDateTime(complaint.createdAt)} />
        <Info
          label="Ditangani oleh"
          value={complaint.handledByName || "-"}
        />
      </div>

      <div className="mt-4">
        <p className="mb-2 text-xs font-bold text-[#253542]">Deskripsi lengkap</p>
        <div className="rounded-2xl border border-[#dce9e7] bg-gradient-to-br from-[#fbfdfc] to-[#f4f8f7] p-4 text-xs leading-6 text-[#465762]">
          {complaint.description}
        </div>
      </div>

      {complaint.evidenceUrl ? (
        <a
          href={complaint.evidenceUrl}
          target="_blank"
          rel="noreferrer"
          className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-[#238d84] hover:underline"
        >
          Lihat bukti keluhan <ExternalLink size={13} />
        </a>
      ) : null}

      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <label>
          <span className="mb-2 block text-xs font-bold text-[#253542]">
            Status
          </span>
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value)}
            className="focus-ring h-10 w-full rounded-xl border border-[#d8e7e4] bg-white px-3 text-xs text-[#253542] shadow-sm"
          >
            <option value="open">Open</option>
            <option value="in_review">In Review</option>
            <option value="resolved">Resolved</option>
            <option value="rejected">Rejected</option>
          </select>
        </label>
        <label className="sm:row-span-2">
          <span className="mb-2 block text-xs font-bold text-[#253542]">
            Catatan resolusi
          </span>
          <textarea
            value={note}
            onChange={(event) => setNote(event.target.value)}
            rows={5}
            className="focus-ring w-full resize-none rounded-xl border border-[#d8e7e4] bg-white px-3 py-2.5 text-xs leading-5 text-[#253542] shadow-sm"
            placeholder="Tambahkan tindak lanjut atau hasil penyelesaian"
          />
        </label>
      </div>
    </Modal>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[10px] uppercase tracking-[0.1em] text-[#8a979f]">
        {label}
      </p>
      <p className="mt-1.5 text-xs font-bold text-[#253542]">{value}</p>
    </div>
  );
}
