export type BadgeTone =
  | "teal"
  | "green"
  | "blue"
  | "amber"
  | "red"
  | "neutral";

export function statusLabel(status: string | null | undefined) {
  switch (status) {
    case "created":
      return "Dibuat";
    case "pending_payment":
      return "Menunggu Pembayaran";
    case "paid":
      return "Dibayar";
    case "scheduled":
      return "Dijadwalkan";
    case "assigned":
      return "Ditugaskan";
    case "in_progress":
      return "Dalam Proses";
    case "proof_uploaded":
      return "Bukti Diunggah";
    case "completed":
      return "Selesai";
    case "cancelled":
      return "Dibatalkan";
    case "complained":
      return "Komplain";
    default:
      return status || "-";
  }
}

export function paymentStatusLabel(status: string | null | undefined) {
  switch (status) {
    case "pending":
    case "pending_payment":
      return "Pending";
    case "paid":
      return "Dibayar";
    case "failed":
      return "Gagal";
    case "expired":
      return "Kedaluwarsa";
    case "refunded":
      return "Refund";
    default:
      return status || "-";
  }
}

export function complaintStatusLabel(status: string | null | undefined) {
  switch (status) {
    case "open":
      return "Open";
    case "in_review":
      return "In Review";
    case "resolved":
      return "Resolved";
    case "rejected":
      return "Rejected";
    default:
      return status || "-";
  }
}

export function badgeTone(status: string | null | undefined): BadgeTone {
  switch (status) {
    case "paid":
    case "completed":
    case "resolved":
      return "green";
    case "scheduled":
    case "assigned":
      return "blue";
    case "in_progress":
    case "pending":
    case "pending_payment":
    case "in_review":
      return "amber";
    case "complained":
    case "open":
    case "failed":
      return "red";
    case "cancelled":
    case "rejected":
    case "expired":
    case "refunded":
      return "neutral";
    default:
      return "neutral";
  }
}

