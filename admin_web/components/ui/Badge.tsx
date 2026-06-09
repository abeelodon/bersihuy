import type { ReactNode } from "react";

import { cn } from "@/lib/utils/cn";
import type { BadgeTone } from "@/lib/utils/status";

const tones: Record<BadgeTone, string> = {
  teal: "border-[#b9e2dd] bg-[#e7f6f3] text-[#247f78]",
  green: "border-[#c5e7d1] bg-[#eaf7ef] text-[#2d7d53]",
  blue: "border-[#c8ddef] bg-[#eaf2fb] text-[#316fa8]",
  amber: "border-[#ecd39f] bg-[#fff4df] text-[#a96f15]",
  red: "border-[#eabeb8] bg-[#ffedea] text-[#b34f43]",
  neutral: "border-[#dce5e4] bg-[#f2f5f5] text-[#65727c]",
};

export function Badge({
  tone = "neutral",
  children,
  className,
}: {
  tone?: BadgeTone;
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex max-w-full items-center rounded-full border px-2.5 py-1 text-[10px] font-bold leading-none",
        tones[tone],
        className,
      )}
    >
      <span className="truncate">{children}</span>
    </span>
  );
}

