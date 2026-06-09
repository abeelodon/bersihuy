"use client";

import type { ReactNode } from "react";
import { useEffect } from "react";
import { X } from "lucide-react";

import { cn } from "@/lib/utils/cn";

export function Modal({
  open,
  onClose,
  title,
  subtitle,
  children,
  footer,
  size = "lg",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: ReactNode;
  footer?: ReactNode;
  size?: "md" | "lg" | "xl";
}) {
  useEffect(() => {
    if (!open) return;
    const listener = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", listener);
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", listener);
      document.body.style.overflow = "";
    };
  }, [onClose, open]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-[#102b2a]/35 p-4 backdrop-blur-[2px]"
      role="dialog"
      aria-modal="true"
      aria-label={title}
      onMouseDown={(event) => {
        if (event.currentTarget === event.target) onClose();
      }}
    >
      <div
        className={cn(
          "surface-shadow flex max-h-[92vh] w-full flex-col overflow-hidden rounded-[22px] border border-[#d8e7e4] bg-white",
          size === "md" && "max-w-xl",
          size === "lg" && "max-w-2xl",
          size === "xl" && "max-w-4xl",
        )}
      >
        <div className="flex items-start gap-4 border-b border-[#e4edeb] px-5 py-4">
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-lg font-bold text-[#172535]">{title}</h2>
            {subtitle ? (
              <p className="mt-1 truncate text-xs text-[#6a7782]">{subtitle}</p>
            ) : null}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="focus-ring grid size-9 place-items-center rounded-xl text-[#6a7782] transition hover:bg-[#eff6f5] hover:text-[#172535]"
            aria-label="Tutup modal"
          >
            <X size={19} />
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-5">{children}</div>
        {footer ? (
          <div className="flex flex-wrap justify-end gap-2 border-t border-[#e4edeb] bg-[#fbfdfc] px-5 py-4">
            {footer}
          </div>
        ) : null}
      </div>
    </div>
  );
}

