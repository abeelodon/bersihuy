"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Boxes,
  ChartNoAxesCombined,
  ClipboardList,
  LayoutDashboard,
  Settings,
  ShieldCheck,
  Users,
  X,
} from "lucide-react";

import { cn } from "@/lib/utils/cn";
import { initials } from "@/lib/utils/format";
import type { AdminProfile } from "@/types/admin";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/analytics", label: "Analytics", icon: ChartNoAxesCombined },
  { href: "/orders", label: "Pesanan", icon: ClipboardList },
  { href: "/staff", label: "Petugas", icon: Users },
  { href: "/catalog", label: "Layanan & Produk", icon: Boxes },
  { href: "/complaints", label: "Keluhan", icon: ShieldCheck },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar({
  profile,
  mobileOpen,
  onClose,
}: {
  profile: AdminProfile;
  mobileOpen: boolean;
  onClose: () => void;
}) {
  const pathname = usePathname();

  return (
    <>
      {mobileOpen ? (
        <button
          className="fixed inset-0 z-30 bg-[#102b2a]/30 lg:hidden"
          onClick={onClose}
          aria-label="Tutup navigasi"
        />
      ) : null}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-40 flex w-[248px] flex-col border-r border-[#dce8e5] bg-white/95 px-4 py-5 shadow-[8px_0_30px_rgba(25,89,83,0.025)] backdrop-blur-xl transition-transform lg:translate-x-0",
          mobileOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex h-12 items-center justify-between px-2">
          <Link href="/dashboard" className="block" onClick={onClose}>
            <Image
              src="/assets/images/logo_full.png"
              alt="Bersihuy"
              width={156}
              height={39}
              className="h-8 w-auto object-contain"
              priority
            />
          </Link>
          <button
            onClick={onClose}
            className="grid size-9 place-items-center rounded-xl text-[#6a7782] hover:bg-[#edf6f4] lg:hidden"
            aria-label="Tutup menu"
          >
            <X size={19} />
          </button>
        </div>

        <p className="mb-2 mt-8 px-3 text-[10px] font-bold uppercase tracking-[0.18em] text-[#96a2a8]">
          Menu utama
        </p>
        <nav className="space-y-1.5">
          {navItems.map((item) => {
            const active = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={cn(
                  "focus-ring relative flex h-11 items-center gap-3 rounded-[14px] px-3 text-[13px] font-semibold transition",
                  active
                    ? "bg-gradient-to-r from-[#dff3f0] to-[#eaf8f6] text-[#197f77] shadow-[0_5px_16px_rgba(36,153,143,0.08)]"
                    : "text-[#52616c] hover:bg-[#f0f7f6] hover:text-[#172535]",
                )}
              >
                {active ? (
                  <span className="absolute left-0 h-5 w-0.5 rounded-full bg-[#24998f]" />
                ) : null}
                <Icon size={18} strokeWidth={active ? 2.2 : 1.8} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="mt-auto rounded-[18px] border border-[#cfe4e0] bg-gradient-to-br from-[#eef9f7] to-[#e7f3f1] p-3.5 shadow-[0_8px_22px_rgba(28,94,88,0.06)]">
          <div className="flex items-center gap-2.5">
            <span className="grid size-10 shrink-0 place-items-center rounded-[13px] bg-gradient-to-br from-[#59c4b9] to-[#218f86] text-xs font-bold text-white shadow-sm">
              {initials(profile.name)}
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-bold text-[#172535]">
                {profile.name}
              </p>
              <p className="mt-0.5 truncate text-[10px] text-[#718089]">
                Admin Panel
              </p>
            </div>
            <span className="size-2.5 rounded-full bg-[#47b881] ring-4 ring-white/70" />
          </div>
        </div>
      </aside>
    </>
  );
}
