import type { InputHTMLAttributes } from "react";

import { cn } from "@/lib/utils/cn";

export function Input({
  className,
  ...props
}: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        "focus-ring h-10 w-full rounded-xl border border-[#d8e6e3] bg-white px-3.5 text-[13px] text-[#172535] shadow-[0_1px_2px_rgba(23,74,69,0.03)] transition placeholder:text-[#94a0a8] focus:border-[#48aaa1] focus:shadow-[0_0_0_4px_rgba(36,153,143,0.07)]",
        className,
      )}
      {...props}
    />
  );
}
