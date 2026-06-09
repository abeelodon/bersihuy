import type { LucideIcon } from "lucide-react";

import { Card } from "@/components/ui/Card";

export function EmptyState({
  icon: Icon,
  title,
  description,
}: {
  icon: LucideIcon;
  title: string;
  description: string;
}) {
  return (
    <Card className="soft-noise relative flex min-h-64 flex-col items-center justify-center overflow-hidden p-8 text-center">
      <div className="absolute inset-x-0 top-0 h-24 bg-gradient-to-b from-[#ebf8f6] to-transparent" />
      <div className="relative mb-4 grid size-14 place-items-center rounded-2xl border border-[#cde8e4] bg-white text-[#24998f] shadow-sm">
        <Icon size={26} strokeWidth={1.8} />
      </div>
      <h3 className="relative text-base font-bold text-[#172535]">{title}</h3>
      <p className="relative mt-1.5 max-w-md text-[13px] leading-6 text-[#6a7782]">
        {description}
      </p>
    </Card>
  );
}
