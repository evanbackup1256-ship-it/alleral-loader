"use client";

import clsx from "clsx";
import { motion } from "motion/react";
import { status, type StatusKind } from "@/lib/design/tokens";
import { spring } from "@/lib/motion/config";

export function HealthRing({
  kind,
  value = 100,
  size = 56,
  stroke = 4,
  label,
  className,
}: {
  kind: StatusKind;
  value?: number;
  size?: number;
  stroke?: number;
  label?: string;
  className?: string;
}) {
  const meta = status[kind];
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.max(0, Math.min(100, value));
  const offset = c - (pct / 100) * c;

  return (
    <div className={clsx("relative inline-grid place-items-center", className)} style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={stroke} />
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={meta.color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={c}
          initial={{ strokeDashoffset: c }}
          animate={{ strokeDashoffset: offset }}
          transition={spring.soft}
          style={{ filter: `drop-shadow(0 0 6px ${meta.glow})` }}
        />
      </svg>
      <div className="absolute text-center">
        <p className="font-mono text-xs font-semibold" style={{ color: meta.color }}>
          {Math.round(pct)}%
        </p>
        {label ? <p className="text-[9px] uppercase tracking-wider text-muted-2">{label}</p> : null}
      </div>
    </div>
  );
}
