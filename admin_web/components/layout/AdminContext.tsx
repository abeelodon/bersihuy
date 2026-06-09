"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import type { AdminDashboardData } from "@/types/admin";

type ToastState = {
  tone: "success" | "error";
  message: string;
} | null;

type AdminContextValue = {
  data: AdminDashboardData;
  query: string;
  setQuery: (query: string) => void;
  reload: () => Promise<void>;
  showToast: (message: string, tone?: "success" | "error") => void;
};

const AdminContext = createContext<AdminContextValue | null>(null);

export function AdminProvider({
  data,
  onReload,
  children,
}: {
  data: AdminDashboardData;
  onReload: () => Promise<void>;
  children: ReactNode;
}) {
  const [query, setQuery] = useState("");
  const [toast, setToast] = useState<ToastState>(null);

  const showToast = useCallback(
    (message: string, tone: "success" | "error" = "success") => {
      setToast({ message, tone });
      window.setTimeout(() => setToast(null), 3500);
    },
    [],
  );

  const value = useMemo(
    () => ({ data, query, setQuery, reload: onReload, showToast }),
    [data, onReload, query, showToast],
  );

  return (
    <AdminContext.Provider value={value}>
      {children}
      {toast ? (
        <div
          className={`fixed bottom-5 right-5 z-[70] max-w-sm rounded-2xl border px-4 py-3 text-sm font-semibold shadow-xl ${
            toast.tone === "success"
              ? "border-[#bde1ce] bg-[#eaf7ef] text-[#2d7d53]"
              : "border-[#eabeb8] bg-[#ffedea] text-[#b34f43]"
          }`}
        >
          {toast.message}
        </div>
      ) : null}
    </AdminContext.Provider>
  );
}

export function useAdmin() {
  const value = useContext(AdminContext);
  if (!value) {
    throw new Error("useAdmin harus digunakan di dalam AdminProvider.");
  }
  return value;
}

