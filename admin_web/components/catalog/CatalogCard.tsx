import { ArrowUpRight, Boxes } from "lucide-react";

import { AssetImage } from "@/components/ui/AssetImage";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";

export function CatalogCard({
  title,
  category,
  price,
  meta,
  imageAssetPath,
  active,
  onDetail,
}: {
  title: string;
  category: string;
  price: string;
  meta: string;
  imageAssetPath: string | null;
  active: boolean;
  onDetail: () => void;
}) {
  return (
    <Card className="group overflow-hidden transition duration-200 hover:-translate-y-0.5 hover:border-[#c4ddd9] hover:shadow-[0_18px_42px_rgba(28,94,88,0.1)]">
      <AssetImage
        src={imageAssetPath}
        alt={title}
        className="h-44 border-b border-[#e2ecea]"
        imageClassName="object-cover transition duration-500 group-hover:scale-[1.03]"
        fallback={<Boxes size={29} />}
      />
      <div className="p-4">
        <div className="flex items-start gap-3">
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-[#172535]">{title}</p>
            <p className="mt-1 truncate text-[11px] font-medium text-[#74818a]">
              {category}
            </p>
          </div>
          <Badge tone={active ? "green" : "neutral"}>
            {active ? "Aktif" : "Nonaktif"}
          </Badge>
        </div>
        <div className="mt-4 flex items-end gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-base font-bold tracking-tight text-[#172535]">
              {price}
            </p>
            <p className="mt-1 truncate text-[10px] text-[#7c8991]">{meta}</p>
          </div>
          <Button
            variant="secondary"
            size="sm"
            className="size-9 px-0"
            onClick={onDetail}
            aria-label={`Lihat detail ${title}`}
          >
            <ArrowUpRight size={15} />
          </Button>
        </div>
      </div>
    </Card>
  );
}
