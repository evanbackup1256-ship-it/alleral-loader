"use client";

import clsx from "clsx";
import { formatFreshness } from "@/lib/status/resolve";
import { useSecondsSince } from "@/lib/hooks/useSecondsSince";

export function FreshnessChip({
  dataUpdatedAt,
  secondsAgo: secondsAgoProp,
  live = false,
  className,
}: {
  dataUpdatedAt?: number | null;
  secondsAgo?: number | null;
  live?: boolean;
  className?: string;
}) {
  const tickSeconds = useSecondsSince(dataUpdatedAt ?? null);
  const secondsAgo = secondsAgoProp ?? tickSeconds;
  const fresh = secondsAgo != null && secondsAgo < 20;

  return (
    <span
      className={clsx(
        "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 font-mono text-[10px]",
        fresh ? "border-cyan-400/30 text-cyan-200" : "border-border text-muted",
        className
      )}
      style={{
        background: fresh ? "rgba(34,211,238,0.08)" : "rgba(255,255,255,0.03)",
        boxShadow: fresh ? "0 0 16px rgba(34,211,238,0.15)" : undefined,
      }}
    >
      {live && fresh ? <span className="freshness-pulse h-1.5 w-1.5 rounded-full bg-cyan-400" /> : null}
      {formatFreshness(secondsAgo)}
    </span>
  );
}
