"use client";

import clsx from "clsx";
import type { LucideIcon } from "lucide-react";

export function MetricCard({
  label,
  value,
  numeric,
  suffix,
  icon: Icon,
  accent = "cyan",
  sparkline,
  trend,
  className,
}: {
  label: string;
  value?: React.ReactNode;
  numeric?: number;
  suffix?: string;
  icon?: LucideIcon;
  accent?: "cyan" | "green" | "violet" | "yellow";
  sparkline?: number[];
  trend?: string;
  className?: string;
}) {
  const accents = {
    cyan: "text-cyan-300",
    green: "text-green-300",
    violet: "text-violet-300",
    yellow: "text-yellow-300",
  };

  return (
    <div className={clsx("obs-metric", className)}>
      <div className="flex items-start justify-between gap-2">
        <p className="obs-kicker">{label}</p>
        {Icon ? <Icon className="h-4 w-4 text-muted-2" strokeWidth={1.75} /> : null}
      </div>
      <p className={clsx("mt-2 stat-value", accents[accent])}>
        {numeric != null ? (
          <>
            {numeric.toLocaleString()}
            {suffix}
          </>
        ) : (
          value
        )}
      </p>
      {trend ? <p className="mt-1 text-[11px] text-muted">{trend}</p> : null}
      {sparkline?.length ? (
        <svg viewBox="0 0 120 28" className={clsx("mt-3 h-7 w-full opacity-70", accents[accent])} preserveAspectRatio="none">
          <polyline
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            points={sparkline
              .map((v, i) => {
                const max = Math.max(...sparkline, 1);
                const x = (i / Math.max(sparkline.length - 1, 1)) * 120;
                const y = 26 - (v / max) * 24;
                return `${x},${y}`;
              })
              .join(" ")}
          />
        </svg>
      ) : null}
    </div>
  );
}
