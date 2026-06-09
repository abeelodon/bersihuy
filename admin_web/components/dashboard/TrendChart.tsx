"use client";

import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { Card } from "@/components/ui/Card";
import { compactRupiah, formatRupiah } from "@/lib/utils/format";
import type { AdminTrendPoint } from "@/types/admin";

export function TrendChart({
  points,
  mode = "orders",
  title,
  subtitle,
}: {
  points: AdminTrendPoint[];
  mode?: "orders" | "revenue";
  title: string;
  subtitle: string;
}) {
  const dataKey = mode === "orders" ? "orders" : "revenue";
  const total = points.reduce((sum, point) => sum + point[dataKey], 0);

  return (
    <Card className="overflow-hidden">
      <div className="flex items-start gap-4 border-b border-[#e8f0ee] px-4 py-4 sm:px-5">
        <div className="min-w-0 flex-1">
          <h2 className="text-[16px] font-bold text-[#172535]">{title}</h2>
          <p className="mt-1 text-xs text-[#74818a]">{subtitle}</p>
        </div>
        <div className="rounded-xl border border-[#d9e9e6] bg-[#f4faf9] px-3 py-2 text-right">
          <p className="text-[9px] font-bold uppercase tracking-[0.1em] text-[#8a979f]">
            7 Hari
          </p>
          <p className="mt-0.5 text-xs font-bold text-[#1d7f77]">
            {mode === "revenue" ? formatRupiah(total) : `${total} pesanan`}
          </p>
        </div>
      </div>
      <div className="h-[282px] w-full px-3 pb-3 pt-5 sm:px-5">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={points} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
            <defs>
              <linearGradient id={`trend-${mode}`} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#35afa4" stopOpacity={0.28} />
                <stop offset="100%" stopColor="#35afa4" stopOpacity={0.02} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke="#edf3f2" strokeDasharray="4 4" vertical={false} />
            <XAxis
              dataKey="label"
              axisLine={false}
              tickLine={false}
              tick={{ fill: "#7d8a93", fontSize: 11 }}
              dy={8}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: "#8b979e", fontSize: 10 }}
              tickFormatter={(value) =>
                mode === "revenue" ? compactRupiah(Number(value)) : String(value)
              }
              allowDecimals={false}
            />
            <Tooltip
              cursor={{ stroke: "#b9dcd8", strokeDasharray: "4 4" }}
              contentStyle={{
                borderRadius: 14,
                border: "1px solid #dce9e7",
                boxShadow: "0 12px 30px rgba(24,91,85,.1)",
                fontSize: 12,
                padding: "10px 12px",
              }}
              formatter={(value) => [
                mode === "revenue"
                  ? formatRupiah(Number(value))
                  : `${Number(value)} pesanan`,
                mode === "revenue" ? "Revenue" : "Pesanan",
              ]}
            />
            <Area
              type="monotone"
              dataKey={dataKey}
              stroke="#24998f"
              strokeWidth={2.5}
              fill={`url(#trend-${mode})`}
              activeDot={{ r: 5, fill: "#24998f", stroke: "#fff", strokeWidth: 3 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}
