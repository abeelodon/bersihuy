"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

import { checkCurrentAdminAccess } from "@/lib/supabase/adminRepository";
import { PageLoader } from "@/components/ui/PageLoader";

export default function HomePage() {
  const router = useRouter();

  useEffect(() => {
    let active = true;
    checkCurrentAdminAccess()
      .then((access) => {
        if (!active) return;
        if (access.profile) {
          router.replace("/dashboard");
        } else {
          router.replace(
            access.reason === "not-admin" ? "/login?error=not-admin" : "/login",
          );
        }
      })
      .catch(() => {
        if (active) router.replace("/login");
      });
    return () => {
      active = false;
    };
  }, [router]);

  return <PageLoader label="Menyiapkan Admin Panel..." fullScreen />;
}
