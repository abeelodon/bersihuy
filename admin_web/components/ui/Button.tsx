import type { ButtonHTMLAttributes, ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "danger" | "ghost";
  size?: "sm" | "md";
  icon?: ReactNode;
};

export function Button({
  className,
  variant = "primary",
  size = "md",
  icon,
  children,
  type = "button",
  ...props
}: ButtonProps) {
  return (
    <button
      type={type}
      className={cn(
        "focus-ring inline-flex items-center justify-center gap-2 rounded-xl font-semibold transition duration-200 disabled:cursor-not-allowed disabled:opacity-55",
        size === "sm" ? "h-9 px-3 text-xs" : "h-10 px-4 text-[13px]",
        variant === "primary" &&
          "bg-gradient-to-r from-[#229f95] to-[#178d84] text-white shadow-[0_7px_18px_rgba(30,157,146,0.2)] hover:-translate-y-0.5 hover:shadow-[0_9px_22px_rgba(30,157,146,0.25)]",
        variant === "secondary" &&
          "border border-[#d8e6e3] bg-white text-[#253542] shadow-[0_1px_2px_rgba(23,74,69,0.04)] hover:border-[#b2d5d0] hover:bg-[#f8fbfa]",
        variant === "danger" &&
          "border border-[#efc6c0] bg-[#fff0ee] text-[#b64e42] hover:bg-[#ffe7e3]",
        variant === "ghost" &&
          "bg-transparent text-[#667680] hover:bg-[#edf6f4] hover:text-[#1a635e]",
        className,
      )}
      {...props}
    >
      {icon}
      {children}
    </button>
  );
}
