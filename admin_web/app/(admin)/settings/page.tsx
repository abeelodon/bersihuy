"use client";

import { useRouter } from "next/navigation";
import {
  CheckCircle2,
  CloudCheck,
  Database,
  FlaskConical,
  KeyRound,
  LockKeyhole,
  LogOut,
  MapPin,
  ShieldCheck,
  Store,
  UserRoundCog,
} from "lucide-react";

import { useAdmin } from "@/components/layout/AdminContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { supabase } from "@/lib/supabase/client";
import { initials } from "@/lib/utils/format";

export default function SettingsPage() {
  const router = useRouter();
  const { data } = useAdmin();

  async function logout() {
    await supabase.auth.signOut();
    router.replace("/login");
  }

  return (
    <section className="grid gap-4 xl:grid-cols-2">
      <Card className="overflow-hidden">
        <SectionHeader
          icon={UserRoundCog}
          title="Admin Profile"
          subtitle="Akun administrator yang sedang aktif"
        />
        <div className="p-5">
          <div className="flex items-center gap-4 rounded-2xl border border-[#d8e8e5] bg-gradient-to-br from-[#f3faf8] to-[#eaf6f4] p-4">
            <span className="grid size-16 shrink-0 place-items-center rounded-[20px] bg-gradient-to-br from-[#65c9bf] to-[#218f86] text-lg font-bold text-white shadow-[0_10px_24px_rgba(36,153,143,0.22)]">
              {initials(data.profile.name)}
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-base font-bold text-[#172535]">
                {data.profile.name}
              </p>
              <p className="mt-1 truncate text-xs text-[#6f7d86]">
                {data.profile.email}
              </p>
              <div className="mt-2 flex flex-wrap gap-2">
                <Badge tone="teal">Administrator</Badge>
                <Badge tone="green">Terverifikasi</Badge>
              </div>
            </div>
          </div>
          <div className="mt-4 grid grid-cols-2 gap-3">
            <MiniInfo
              icon={ShieldCheck}
              label="Hak Akses"
              value="Full Admin"
            />
            <MiniInfo
              icon={MapPin}
              label="Area Operasi"
              value="Semarang"
            />
          </div>
          <Button
            variant="secondary"
            className="mt-5"
            icon={<LogOut size={16} />}
            onClick={() => void logout()}
          >
            Keluar dari akun
          </Button>
        </div>
      </Card>

      <SettingsCard
        title="Business Settings"
        subtitle="Konfigurasi operasional Bersihuy"
        icon={Store}
        rows={[
          ["Admin fee", "Rp5.000"],
          ["Service area", "Semarang"],
          ["Payment provider", "Dummy / Midtrans later"],
          ["App mode", "Development"],
        ]}
      />

      <SettingsCard
        title="Data & Security"
        subtitle="Perlindungan akses dan koneksi data"
        icon={LockKeyhole}
        rows={[
          ["Row Level Security", "Aktif"],
          ["Supabase connection", "Terhubung"],
          ["Frontend key", "Anon / Publishable only"],
          ["Secret key", "Tidak disimpan di frontend"],
        ]}
      />

      <Card className="overflow-hidden">
        <SectionHeader
          icon={CloudCheck}
          title="System Status"
          subtitle="Kondisi layanan panel administrasi"
        />
        <div className="space-y-2.5 p-5">
          <Status icon={Database} label="Database" value="Supabase connected" />
          <Status icon={CloudCheck} label="Connection" value="Terhubung" />
          <Status icon={KeyRound} label="Akses data" value="RLS protected" />
          <Status
            icon={FlaskConical}
            label="Environment"
            value="Development"
            amber
          />
        </div>
      </Card>
    </section>
  );
}

function SectionHeader({
  icon: Icon,
  title,
  subtitle,
}: {
  icon: typeof Store;
  title: string;
  subtitle: string;
}) {
  return (
    <div className="flex items-center gap-3 border-b border-[#e8f0ee] bg-[#fbfdfc] px-5 py-4">
      <span className="grid size-10 place-items-center rounded-[13px] bg-[#e7f6f3] text-[#24998f]">
        <Icon size={18} />
      </span>
      <div>
        <h2 className="text-[15px] font-bold text-[#172535]">{title}</h2>
        <p className="mt-1 text-[10px] text-[#74818a]">{subtitle}</p>
      </div>
    </div>
  );
}

function SettingsCard({
  title,
  subtitle,
  icon,
  rows,
}: {
  title: string;
  subtitle: string;
  icon: typeof Store;
  rows: [string, string][];
}) {
  return (
    <Card className="overflow-hidden">
      <SectionHeader icon={icon} title={title} subtitle={subtitle} />
      <div className="divide-y divide-[#e8f0ee] px-5 py-2">
        {rows.map(([label, value]) => (
          <div key={label} className="flex items-center gap-4 py-3.5">
            <span className="flex-1 text-xs text-[#6a7782]">{label}</span>
            <span className="inline-flex items-center gap-1.5 text-right text-xs font-bold text-[#253542]">
              <CheckCircle2 size={13} className="text-[#43a572]" />
              {value}
            </span>
          </div>
        ))}
      </div>
    </Card>
  );
}

function MiniInfo({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof ShieldCheck;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-2xl border border-[#e0ebe9] bg-[#fbfdfc] p-3">
      <Icon size={15} className="text-[#24998f]" />
      <p className="mt-2 text-[9px] font-bold uppercase tracking-[0.1em] text-[#8b979e]">
        {label}
      </p>
      <p className="mt-1 text-xs font-bold text-[#253542]">{value}</p>
    </div>
  );
}

function Status({
  icon: Icon,
  label,
  value,
  amber,
}: {
  icon: typeof Database;
  label: string;
  value: string;
  amber?: boolean;
}) {
  return (
    <div
      className={`flex items-center gap-3 rounded-2xl border px-3.5 py-3 ${
        amber
          ? "border-[#ecd39f] bg-[#fff9ee] text-[#a96f15]"
          : "border-[#cfe6d7] bg-[#f0f9f3] text-[#2d7d53]"
      }`}
    >
      <span className="grid size-8 place-items-center rounded-xl bg-white/70">
        <Icon size={15} />
      </span>
      <span className="flex-1 text-xs font-semibold">{label}</span>
      <span className="text-[11px] font-bold">{value}</span>
    </div>
  );
}
