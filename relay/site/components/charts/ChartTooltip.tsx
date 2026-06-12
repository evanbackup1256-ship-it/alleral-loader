"use client";

import clsx from "clsx";
import { motion, AnimatePresence } from "motion/react";
import { spring } from "@/lib/motion/config";
import type { LucideIcon } from "lucide-react";

export function ChartTooltip({
  open,
  x,
  y,
  title,
  rows,
  icon: Icon,
}: {
  open: boolean;
  x: number;
  y: number;
  title: string;
  rows: { label: string; value: string; accent?: string }[];
  icon?: LucideIcon;
}) {
  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          initial={{ opacity: 0, scale: 0.92, y: 8 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.94, y: 4 }}
          transition={spring.tooltip}
          className="chart-tooltip pointer-events-none absolute z-50 min-w-[180px]"
          style={{ left: x, top: y, transform: "translate(-50%, calc(-100% - 12px))" }}
        >
          <div className="flex items-center gap-2 border-b border-white/10 pb-2">
            {Icon ? <Icon className="h-3.5 w-3.5 text-cyan-300" strokeWidth={2} /> : null}
            <strong className="text-xs font-semibold text-text">{title}</strong>
          </div>
          <dl className="mt-2 space-y-1.5">
            {rows.map((row) => (
              <div key={row.label} className="flex items-center justify-between gap-4 text-[11px]">
                <dt className="text-muted">{row.label}</dt>
                <dd className={clsx("font-mono font-medium", row.accent || "text-text")}>{row.value}</dd>
              </div>
            ))}
          </dl>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
