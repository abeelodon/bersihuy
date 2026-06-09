import type { HTMLAttributes } from "react";

import { cn } from "@/lib/utils/cn";

export function Card({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "surface-shadow rounded-[22px] border border-[#dce8e5] bg-white",
        className,
      )}
      {...props}
    />
  );
}
