"use client";

import clsx from "clsx";
import { status, type StatusKind } from "@/lib/design/tokens";
import { shouldStatusPulse } from "@/lib/status/resolve";

export function StatusPill({
  kind,
  label,
  pulse,
  size = "md",
  className,
}: {
  kind: StatusKind;
  label?: string;
  pulse?: boolean;
  size?: "sm" | "md";
  className?: string;
}) {
  const meta = status[kind];
  const text = label ?? meta.label;
  const showPulse = shouldStatusPulse(kind, pulse);

  return (
    <span
      className={clsx(
        "inline-flex items-center gap-2 rounded-full border font-medium",
        size === "sm" ? "px-2 py-0.5 text-[10px]" : "px-2.5 py-1 text-[11px]",
        showPulse && "status-live-pulse",
        className
      )}
      style={{
        borderColor: `${meta.color}33`,
        background: `linear-gradient(135deg, ${meta.color}14, ${meta.color}06)`,
        color: meta.color,
      }}
    >
      <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: meta.color, boxShadow: `0 0 6px ${meta.glow}` }} />
      {text}
    </span>
  );
}
