import { LoaderCircle } from "lucide-react";

import { cn } from "@/lib/utils/cn";

export function PageLoader({
  label = "Memuat data...",
  fullScreen = false,
}: {
  label?: string;
  fullScreen?: boolean;
}) {
  return (
    <div
      className={cn(
        "flex items-center justify-center",
        fullScreen
          ? "min-h-screen bg-[radial-gradient(circle_at_50%_40%,#e2f5f2,transparent_25rem),#f4f8f7]"
          : "min-h-[360px]",
      )}
    >
      <div className="flex flex-col items-center gap-3 rounded-2xl border border-[#dce8e5] bg-white px-7 py-6 text-[#6a7782] shadow-[0_16px_40px_rgba(28,94,88,0.08)]">
        <LoaderCircle className="animate-spin text-[#24998f]" size={30} />
        <span className="text-sm font-medium">{label}</span>
      </div>
    </div>
  );
}
