"use client";

import { useCallback, useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import { AdminProvider } from "@/components/layout/AdminContext";
import { Sidebar } from "@/components/layout/Sidebar";
import { Topbar } from "@/components/layout/Topbar";
import { ErrorState } from "@/components/ui/ErrorState";
import { PageLoader } from "@/components/ui/PageLoader";
import {
  loadDashboardData,
  requireAdminProfile,
} from "@/lib/supabase/adminRepository";
import { supabase } from "@/lib/supabase/client";
import type { AdminDashboardData } from "@/types/admin";

export function AdminShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [data, setData] = useState<AdminDashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [redirecting, setRedirecting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mobileOpen, setMobileOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const profile = await requireAdminProfile();
      if (!profile) {
        setRedirecting(true);
        setData(null);
        router.replace("/login");
        return;
      }
      setData(await loadDashboardData(profile));
    } catch (caught) {
      const message =
        caught instanceof Error ? caught.message : "Gagal memuat Admin Panel.";
      if (message.includes("Akun ini bukan admin")) {
        setRedirecting(true);
        router.replace("/login?error=not-admin");
        return;
      }
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    let active = true;

    async function initialize() {
      try {
        const profile = await requireAdminProfile();
        if (!profile) {
          if (active) setRedirecting(true);
          router.replace("/login");
          return;
        }
        const loaded = await loadDashboardData(profile);
        if (active) setData(loaded);
      } catch (caught) {
        if (!active) return;
        const message =
          caught instanceof Error ? caught.message : "Gagal memuat Admin Panel.";
        if (message.includes("Akun ini bukan admin")) {
          setRedirecting(true);
          router.replace("/login?error=not-admin");
          return;
        }
        setError(message);
      } finally {
        if (active) setLoading(false);
      }
    }

    void initialize();
    return () => {
      active = false;
    };
  }, [router]);

  async function logout() {
    await supabase.auth.signOut();
    router.replace("/login");
  }

  if ((loading || redirecting) && !data) {
    return <PageLoader label="Memuat data operasional Bersihuy..." fullScreen />;
  }

  if (!data) {
    return (
      <main className="min-h-screen p-5 sm:p-8">
        <div className="mx-auto max-w-4xl">
          <ErrorState
            message={error || "Sesi admin tidak tersedia."}
            onRetry={() => void load()}
          />
        </div>
      </main>
    );
  }

  return (
    <AdminProvider data={data} onReload={load}>
      <Sidebar
        profile={data.profile}
        mobileOpen={mobileOpen}
        onClose={() => setMobileOpen(false)}
      />
      <main className="min-h-screen px-4 py-5 sm:px-6 lg:ml-[248px] lg:px-7 lg:py-6">
        <div className="mx-auto max-w-[1540px]">
          <Topbar onMenu={() => setMobileOpen(true)} onLogout={logout} />
          {loading ? (
            <div className="mb-4 h-1 overflow-hidden rounded-full bg-[#dcece9]">
              <div className="h-full w-1/3 animate-pulse rounded-full bg-[#24998f]" />
            </div>
          ) : null}
          {error ? (
            <div className="mb-4 rounded-xl border border-[#eabeb8] bg-[#ffedea] px-4 py-3 text-xs font-medium text-[#a84a40]">
              {error}
            </div>
          ) : null}
          {children}
        </div>
      </main>
    </AdminProvider>
  );
}
