import { Card } from "@/components/ui/Card";
import type { AdminDashboardSummary } from "@/types/admin";

const rows = [
  { key: "waitingAssignment", label: "Belum Ditugaskan", color: "#d99a2b" },
  { key: "assigned", label: "Ditugaskan", color: "#4f8fca" },
  { key: "inProgress", label: "Dalam Proses", color: "#2da89d" },
  { key: "completed", label: "Selesai", color: "#48a976" },
] as const;

export function StatusSummary({
  summary,
}: {
  summary: AdminDashboardSummary;
}) {
  const total = Math.max(summary.totalOrders, 1);
  const completed = Math.round((summary.completed / total) * 100);
  const inProgress = Math.round((summary.inProgress / total) * 100);

  return (
    <Card className="overflow-hidden">
      <div className="border-b border-[#e8f0ee] px-4 py-4 sm:px-5">
        <h2 className="text-[16px] font-bold text-[#172535]">
          Ringkasan Status
        </h2>
        <p className="mt-1 text-xs text-[#74818a]">
          Distribusi operasional pesanan
        </p>
      </div>

      <div className="grid gap-5 p-4 sm:p-5 lg:grid-cols-[132px_1fr] xl:grid-cols-1 2xl:grid-cols-[132px_1fr]">
        <div className="grid place-items-center">
          <div
            className="grid size-32 place-items-center rounded-full"
            style={{
              background: `conic-gradient(#48a976 0 ${completed}%, #2da89d ${completed}% ${Math.min(100, completed + inProgress)}%, #e8f0ee ${Math.min(100, completed + inProgress)}% 100%)`,
            }}
          >
            <div className="grid size-[92px] place-items-center rounded-full bg-white text-center shadow-inner">
              <div>
                <p className="text-[25px] font-bold tracking-tight text-[#172535]">
                  {summary.totalOrders}
                </p>
                <p className="text-[9px] font-semibold uppercase tracking-[0.12em] text-[#8a979f]">
                  Pesanan
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-3.5">
          {rows.map((row) => {
            const value = summary[row.key];
            const percentage = Math.min(100, (value / total) * 100);
            return (
              <div key={row.key}>
                <div className="mb-1.5 flex items-center gap-2">
                  <span
                    className="size-2 rounded-full"
                    style={{ backgroundColor: row.color }}
                  />
                  <span className="flex-1 text-[11px] font-medium text-[#667680]">
                    {row.label}
                  </span>
                  <span className="text-[11px] font-bold text-[#172535]">
                    {value}
                  </span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-[#edf3f2]">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${percentage}%`,
                      backgroundColor: row.color,
                    }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </Card>
  );
}
