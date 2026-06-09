"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  BarChart3,
  ClipboardList,
  Eye,
  EyeOff,
  LoaderCircle,
  LockKeyhole,
  Mail,
  Sparkles,
  UserCheck,
} from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import {
  checkCurrentAdminAccess,
  requireAdminProfile,
} from "@/lib/supabase/adminRepository";
import { supabase } from "@/lib/supabase/client";

export function LoginForm({ notAdmin = false }: { notAdmin?: boolean }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [checking, setChecking] = useState(true);
  const [error, setError] = useState(notAdmin ? "Akun ini bukan admin." : "");

  useEffect(() => {
    let active = true;
    checkCurrentAdminAccess()
      .then((access) => {
        if (!active) return;
        if (access.profile) {
          router.replace("/dashboard");
        } else if (access.reason === "not-admin") {
          setError("Akun ini bukan admin.");
        }
      })
      .finally(() => {
        if (active) setChecking(false);
      });
    return () => {
      active = false;
    };
  }, [router]);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });
      if (signInError) throw signInError;
      const profile = await requireAdminProfile();
      if (!profile) throw new Error("Sesi admin tidak ditemukan.");
      router.replace("/dashboard");
    } catch (caught) {
      const message =
        caught instanceof Error ? caught.message : "Login admin gagal.";
      if (message.includes("Akun ini bukan admin")) {
        await supabase.auth.signOut();
        setError("Akun ini bukan admin.");
      } else {
        setError(
          message.toLowerCase().includes("invalid login")
            ? "Email atau password tidak sesuai."
            : message,
        );
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#eef7f5] p-4 sm:p-6">
      <div className="absolute -left-24 top-10 size-96 rounded-full bg-[#70d5c8]/20 blur-3xl" />
      <div className="absolute -right-20 bottom-0 size-[28rem] rounded-full bg-[#2ba99e]/12 blur-3xl" />
      <div className="soft-noise absolute inset-0 opacity-25" />

      <div className="relative grid min-w-0 w-full max-w-[1080px] grid-cols-[minmax(0,1fr)] overflow-hidden rounded-[30px] border border-white/80 bg-white shadow-[0_34px_100px_rgba(24,91,85,0.16)] lg:grid-cols-[1.06fr_0.94fr]">
        <section className="premium-grid relative hidden min-h-[660px] flex-col justify-between overflow-hidden bg-gradient-to-br from-[#176f69] via-[#1c9188] to-[#41b9ad] p-10 text-white lg:flex">
          <div className="absolute -right-24 -top-24 size-72 rounded-full border-[42px] border-white/[0.06]" />
          <div className="absolute -bottom-20 -left-16 size-64 rounded-full bg-[#8be0d6]/20 blur-2xl" />

          <div className="relative">
            <div className="inline-flex rounded-2xl bg-white px-4 py-3 shadow-[0_10px_30px_rgba(8,70,65,0.15)]">
              <Image
                src="/assets/images/logo_full.png"
                alt="Bersihuy"
                width={170}
                height={43}
                className="h-8 w-auto object-contain"
                priority
              />
            </div>
          </div>

          <div className="relative">
            <span className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold backdrop-blur-sm">
              <Sparkles size={13} />
              Admin Operations
            </span>
            <h1 className="mt-5 max-w-md text-[39px] font-bold leading-[1.14] tracking-[-0.045em]">
              Operasional bersih, keputusan lebih cepat.
            </h1>
            <p className="mt-4 max-w-md text-sm leading-7 text-white/75">
              Pantau pesanan, petugas, layanan, pendapatan, dan kualitas
              pelayanan Bersihuy dari satu dashboard.
            </p>

            <div className="mt-7 grid grid-cols-2 gap-3">
              <PreviewMetric icon={ClipboardList} value="12" label="Pesanan" />
              <PreviewMetric
                icon={UserCheck}
                value="7"
                label="Menunggu Penugasan"
              />
              <PreviewMetric
                icon={BarChart3}
                value="Rp1,87 jt"
                label="Revenue"
              />
              <PreviewMetric
                icon={Sparkles}
                value="1"
                label="Petugas Aktif"
              />
            </div>
          </div>

          <p className="relative text-xs text-white/60">
            Bersihuy Admin Panel &middot; Semarang
          </p>
        </section>

        <section className="flex min-h-[660px] min-w-0 items-center px-6 py-10 sm:px-14">
          <div className="mx-auto min-w-0 w-full max-w-sm">
            <div className="mb-9">
              <Image
                src="/assets/images/logo_full.png"
                alt="Bersihuy"
                width={176}
                height={44}
                className="h-9 w-auto object-contain"
                priority
              />
            </div>

            <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-[#24998f]">
              Admin Panel
            </p>
            <h2 className="mt-3 text-[32px] font-bold tracking-[-0.045em] text-[#172535]">
              Selamat datang
            </h2>
            <p className="mt-2 break-words text-[13px] leading-6 text-[#6a7782]">
              Masuk menggunakan akun admin Bersihuy untuk melanjutkan.
            </p>

            <form className="mt-8 min-w-0 space-y-4" onSubmit={submit}>
              <label className="block">
                <span className="mb-2 block text-xs font-semibold text-[#354652]">
                  Email
                </span>
                <div className="relative">
                  <Mail
                    className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#7b8992]"
                    size={17}
                  />
                  <Input
                    type="email"
                    autoComplete="email"
                    required
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    className="h-12 rounded-[14px] pl-10"
                    placeholder="nama@bersihuy.com"
                  />
                </div>
              </label>
              <label className="block">
                <span className="mb-2 block text-xs font-semibold text-[#354652]">
                  Password
                </span>
                <div className="relative">
                  <LockKeyhole
                    className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#7b8992]"
                    size={17}
                  />
                  <Input
                    type={showPassword ? "text" : "password"}
                    autoComplete="current-password"
                    required
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    className="h-12 rounded-[14px] px-10"
                    placeholder="Masukkan password"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((value) => !value)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-[#7b8992] transition hover:text-[#172535]"
                    aria-label={
                      showPassword ? "Sembunyikan password" : "Tampilkan password"
                    }
                  >
                    {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
                  </button>
                </div>
              </label>

              {error ? (
                <div className="rounded-[14px] border border-[#eabeb8] bg-[#ffedea] px-3.5 py-3 text-xs font-medium text-[#aa4b41]">
                  {error}
                </div>
              ) : null}

              <Button
                type="submit"
                className="mt-2 h-12 w-full rounded-[14px]"
                disabled={loading || checking}
                icon={
                  loading || checking ? (
                    <LoaderCircle className="animate-spin" size={17} />
                  ) : undefined
                }
              >
                {checking
                  ? "Memeriksa sesi..."
                  : loading
                    ? "Memproses..."
                    : "Masuk ke Dashboard"}
              </Button>
            </form>

            <p className="mt-7 break-words text-center text-[11px] leading-5 text-[#8a979f]">
              Akses khusus administrator. Aktivitas login dan perubahan data
              tercatat melalui Supabase.
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}

function PreviewMetric({
  icon: Icon,
  value,
  label,
}: {
  icon: typeof ClipboardList;
  value: string;
  label: string;
}) {
  return (
    <div className="rounded-2xl border border-white/15 bg-white/[0.11] p-3.5 backdrop-blur-md">
      <div className="flex items-center justify-between">
        <p className="text-lg font-bold tracking-tight">{value}</p>
        <span className="grid size-8 place-items-center rounded-xl bg-white/15">
          <Icon size={15} />
        </span>
      </div>
      <p className="mt-1 text-[10px] font-medium text-white/65">{label}</p>
    </div>
  );
}
