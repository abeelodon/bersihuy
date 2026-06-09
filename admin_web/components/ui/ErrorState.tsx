import { CloudOff } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";

export function ErrorState({
  message,
  onRetry,
}: {
  message: string;
  onRetry?: () => void;
}) {
  return (
    <Card className="flex min-h-[340px] flex-col items-center justify-center p-8 text-center">
      <div className="grid size-14 place-items-center rounded-2xl bg-[#ffedea] text-[#b34f43]">
        <CloudOff size={27} />
      </div>
      <h3 className="mt-4 text-lg font-bold text-[#172535]">
        Data tidak dapat dimuat
      </h3>
      <p className="mt-1.5 max-w-xl text-[13px] leading-6 text-[#6a7782]">
        {message}
      </p>
      {onRetry ? (
        <Button className="mt-5" onClick={onRetry}>
          Muat ulang
        </Button>
      ) : null}
    </Card>
  );
}

