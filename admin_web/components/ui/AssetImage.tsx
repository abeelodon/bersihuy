"use client";

import { useState, type ReactNode } from "react";
import { ImageOff } from "lucide-react";

import { cn } from "@/lib/utils/cn";
import { normalizeAssetPath } from "@/lib/utils/assets";

export function AssetImage({
  src,
  alt,
  className,
  imageClassName,
  fallback,
}: {
  src: string | null | undefined;
  alt: string;
  className?: string;
  imageClassName?: string;
  fallback?: ReactNode;
}) {
  const normalized = normalizeAssetPath(src);
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  const failed = Boolean(normalized && failedSrc === normalized);

  return (
    <div
      className={cn(
        "relative overflow-hidden bg-gradient-to-br from-[#eef8f6] to-[#e7f1ef]",
        className,
      )}
    >
      {normalized && !failed ? (
        // Dynamic paths come from Supabase and can include local or remote assets.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={normalized}
          alt={alt}
          className={cn("h-full w-full object-cover", imageClassName)}
          onError={() => setFailedSrc(normalized)}
        />
      ) : (
        <div className="grid h-full w-full place-items-center text-[#73aaa4]">
          {fallback || <ImageOff size={24} strokeWidth={1.7} />}
        </div>
      )}
    </div>
  );
}
