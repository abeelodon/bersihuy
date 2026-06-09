const rupiah = new Intl.NumberFormat("id-ID", {
  style: "currency",
  currency: "IDR",
  maximumFractionDigits: 0,
});

const date = new Intl.DateTimeFormat("id-ID", {
  day: "2-digit",
  month: "short",
  year: "numeric",
});

const dateTime = new Intl.DateTimeFormat("id-ID", {
  day: "2-digit",
  month: "short",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

export function formatRupiah(value: number) {
  return rupiah.format(Number.isFinite(value) ? value : 0).replace(/\s/g, "");
}

export function formatDate(value: string | Date | null | undefined) {
  if (!value) return "-";
  const parsed = value instanceof Date ? value : new Date(value);
  return Number.isNaN(parsed.getTime()) ? "-" : date.format(parsed);
}

export function formatDateTime(value: string | Date | null | undefined) {
  if (!value) return "-";
  const parsed = value instanceof Date ? value : new Date(value);
  return Number.isNaN(parsed.getTime()) ? "-" : dateTime.format(parsed);
}

export function compactRupiah(value: number) {
  if (value >= 1_000_000_000) {
    return `Rp${(value / 1_000_000_000).toFixed(1)}M`;
  }
  if (value >= 1_000_000) {
    return `Rp${(value / 1_000_000).toFixed(1)}jt`;
  }
  if (value >= 1_000) {
    return `Rp${Math.round(value / 1_000)}rb`;
  }
  return `Rp${value}`;
}

export function initials(name: string) {
  const words = name.trim().split(/\s+/).filter(Boolean).slice(0, 2);
  return words.length ? words.map((word) => word[0].toUpperCase()).join("") : "A";
}

