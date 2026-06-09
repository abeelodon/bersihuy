import type { LucideIcon } from "lucide-react";

import { Card } from "@/components/ui/Card";
import { cn } from "@/lib/utils/cn";

const accents = {
  teal: {
    icon: "bg-[#e3f6f3] text-[#247f78]",
    glow: "bg-[#53c8ba]",
    line: "from-[#5bcabd] to-[#269e94]",
  },
  green: {
    icon: "bg-[#e8f7ee] text-[#2d7d53]",
    glow: "bg-[#70c792]",
    line: "from-[#78c997] to-[#3da56c]",
  },
  blue: {
    icon: "bg-[#e9f2fb] text-[#316fa8]",
    glow: "bg-[#72aee0]",
    line: "from-[#79b1df] to-[#4b8fc8]",
  },
  amber: {
    icon: "bg-[#fff3dc] text-[#a96f15]",
    glow: "bg-[#e3b45f]",
    line: "from-[#e7b865] to-[#d39229]",
  },
  red: {
    icon: "bg-[#ffebe8] text-[#b34f43]",
    glow: "bg-[#e88e83]",
    line: "from-[#e8968b] to-[#d8675b]",
  },
};

export function StatCard({
  label,
  value,
  helper,
  icon: Icon,
  accent = "teal",
}: {
  label: string;
  value: string;
  helper: string;
  icon: LucideIcon;
  accent?: keyof typeof accents;
}) {
  const tone = accents[accent];

  return (
    <Card className="group relative min-h-[132px] overflow-hidden p-4 transition duration-200 hover:-translate-y-0.5 hover:border-[#c8ddda] hover:shadow-[0_16px_38px_rgba(28,94,88,0.09)]">
      <span
        className={cn(
          "absolute -right-7 -top-8 size-20 rounded-full opacity-[0.08] blur-xl",
          tone.glow,
        )}
      />
      <div className="relative flex items-start gap-3">
        <p className="min-w-0 flex-1 text-xs font-semibold leading-5 text-[#6a7782]">
          {label}
        </p>
        <div
          className={cn(
            "grid size-9 shrink-0 place-items-center rounded-[13px] transition group-hover:scale-105",
            tone.icon,
          )}
        >
          <Icon size={18} strokeWidth={1.9} />
        </div>
      </div>
      <p className="relative mt-3 truncate text-[24px] font-bold tracking-[-0.035em] text-[#172535]">
        {value}
      </p>
      <div className="relative mt-1.5 flex items-center gap-2">
        <span
          className={cn(
            "h-1 w-8 rounded-full bg-gradient-to-r",
            tone.line,
          )}
        />
        <p className="truncate text-[10px] font-medium text-[#7d8a93]">
          {helper}
        </p>
      </div>
    </Card>
  );
}
