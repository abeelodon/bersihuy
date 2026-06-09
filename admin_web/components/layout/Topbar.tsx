"use client";

import { LogOut, Menu, RefreshCw, Search, ShieldCheck } from "lucide-react";
import { usePathname } from "next/navigation";

import { Button } from "@/components/ui/Button";
import { useAdmin } from "@/components/layout/AdminContext";

const pageMeta: Record<string, { title: string; subtitle: string }> = {
  "/dashboard": {
    title: "Dashboard",
    subtitle: "Pantau operasional Bersihuy hari ini",
  },
  "/analytics": {
    title: "Analytics",
    subtitle: "Laporan performa layanan dan operasional Bersihuy",
  },
  "/orders": {
    title: "Pesanan",
    subtitle: "Kelola pesanan customer dan penugasan petugas",
  },
  "/staff": {
    title: "Petugas",
    subtitle: "Kelola data dan performa petugas Bersihuy",
  },
  "/catalog": {
    title: "Layanan & Produk",
    subtitle: "Kelola katalog layanan dan produk tambahan Bersihuy",
  },
  "/complaints": {
    title: "Keluhan",
    subtitle: "Pantau dan tindak lanjuti keluhan customer",
  },
  "/settings": {
    title: "Settings",
    subtitle: "Pengaturan admin dan konfigurasi aplikasi",
  },
};

export function Topbar({
  onMenu,
  onLogout,
}: {
  onMenu: () => void;
  onLogout: () => void;
}) {
  const pathname = usePathname();
  const meta = pageMeta[pathname] || pageMeta["/dashboard"];
  const { query, setQuery, reload } = useAdmin();

  return (
    <header className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-center">
      <div className="flex min-w-0 flex-1 items-start gap-3">
        <button
          onClick={onMenu}
          className="focus-ring mt-0.5 grid size-10 shrink-0 place-items-center rounded-xl border border-[#d8e7e4] bg-white text-[#50606b] lg:hidden"
          aria-label="Buka menu"
        >
          <Menu size={19} />
        </button>
        <div className="min-w-0">
          <h1 className="truncate text-[28px] font-bold tracking-[-0.04em] text-[#172535]">
            {meta.title}
          </h1>
          <p className="mt-1 text-[13px] text-[#6a7782]">{meta.subtitle}</p>
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-2.5">
        <label className="relative min-w-[220px] flex-1 xl:w-72 xl:flex-none">
          <Search
            className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6f7d86]"
            size={17}
          />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            className="focus-ring h-10 w-full rounded-[13px] border border-[#d8e6e3] bg-white pl-10 pr-3 text-xs text-[#172535] shadow-[0_4px_16px_rgba(28,94,88,0.035)] placeholder:text-[#98a3aa] focus:border-[#48aaa1]"
            placeholder={`Cari di ${meta.title.toLowerCase()}`}
            aria-label={`Cari di ${meta.title}`}
          />
        </label>
        <Button
          variant="secondary"
          className="w-10 px-0"
          icon={<RefreshCw size={16} />}
          onClick={() => void reload()}
          aria-label="Muat ulang data"
        />
        <span className="hidden h-10 items-center gap-2 rounded-[13px] border border-[#d8e6e3] bg-white px-3 text-[11px] font-semibold text-[#58706f] shadow-[0_4px_16px_rgba(28,94,88,0.035)] 2xl:flex">
          <ShieldCheck size={15} className="text-[#24998f]" />
          Admin terverifikasi
        </span>
        <Button
          variant="secondary"
          icon={<LogOut size={16} />}
          onClick={onLogout}
          className="px-3"
        >
          <span className="hidden sm:inline">Keluar</span>
        </Button>
      </div>
    </header>
  );
}
