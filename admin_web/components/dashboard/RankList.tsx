import type { LucideIcon } from "lucide-react";
import { ArrowUpRight } from "lucide-react";

import { AssetImage } from "@/components/ui/AssetImage";
import { Card } from "@/components/ui/Card";
import { formatRupiah } from "@/lib/utils/format";
import type { AdminTopItem } from "@/types/admin";

export function RankList({
  title,
  subtitle,
  items,
  icon: Icon,
}: {
  title: string;
  subtitle: string;
  items: AdminTopItem[];
  icon: LucideIcon;
}) {
  return (
    <Card className="overflow-hidden">
      <div className="flex items-start gap-3 border-b border-[#e8f0ee] px-4 py-4 sm:px-5">
        <div className="min-w-0 flex-1">
          <h2 className="text-[16px] font-bold text-[#172535]">{title}</h2>
          <p className="mt-1 text-xs text-[#74818a]">{subtitle}</p>
        </div>
        <span className="grid size-9 place-items-center rounded-xl bg-[#ecf7f5] text-[#24998f]">
          <ArrowUpRight size={17} />
        </span>
      </div>

      <div className="px-4 py-2 sm:px-5">
        {items.length ? (
          items.slice(0, 5).map((item, index) => (
            <div
              key={item.name}
              className="group flex items-center gap-3 border-b border-[#e9f0ef] py-3 last:border-0"
            >
              <span className="w-4 text-center text-[10px] font-bold text-[#9aa5aa]">
                {String(index + 1).padStart(2, "0")}
              </span>
              <AssetImage
                src={item.imageAssetPath}
                alt={item.name}
                className="size-12 shrink-0 rounded-[14px] border border-[#e2ecea]"
                imageClassName="object-cover transition duration-300 group-hover:scale-105"
                fallback={<Icon size={18} />}
              />
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-bold text-[#243540]">
                  {item.name}
                </p>
                <p className="mt-1 truncate text-[10px] text-[#7a8790]">
                  {item.count} dipesan
                  {item.revenue
                    ? ` \u00b7 ${formatRupiah(item.revenue)}`
                    : ""}
                </p>
              </div>
              <span className="rounded-full bg-[#eef7f5] px-2 py-1 text-[9px] font-bold text-[#338c84]">
                Top {index + 1}
              </span>
            </div>
          ))
        ) : (
          <div className="flex min-h-56 flex-col items-center justify-center text-center">
            <span className="grid size-12 place-items-center rounded-2xl bg-[#edf7f5] text-[#75aaa4]">
              <Icon size={23} />
            </span>
            <p className="mt-3 text-xs text-[#74818a]">
              Belum ada data penjualan.
            </p>
          </div>
        )}
      </div>
    </Card>
  );
}
