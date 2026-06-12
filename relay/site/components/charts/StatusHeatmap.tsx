"use client";

import clsx from "clsx";
import { motion } from "motion/react";
import { resolveGameStatus } from "@/lib/status/resolve";
import { status } from "@/lib/design/tokens";
import { spring } from "@/lib/motion/config";

const KINDS = ["healthy", "syncing", "warning", "error", "idle"] as const;

export function StatusHeatmap({
  games,
  className,
}: {
  games: { id: string; name?: string; status?: string }[];
  className?: string;
}) {
  const counts = KINDS.reduce(
    (acc, k) => {
      acc[k] = games.filter((g) => resolveGameStatus(g.status) === k).length;
      return acc;
    },
    {} as Record<(typeof KINDS)[number], number>
  );
  const max = Math.max(1, ...Object.values(counts));

  return (
    <div className={clsx("obs-panel", className)}>
      <div className="obs-panel-head">
        <div>
          <p className="obs-kicker">Status heatmap</p>
          <h3 className="obs-title-sm">Script health distribution</h3>
        </div>
      </div>
      <div className="mt-4 grid grid-cols-5 gap-2">
        {KINDS.map((kind, i) => {
          const n = counts[kind];
          const intensity = n / max;
          const meta = status[kind];
          return (
            <motion.div
              key={kind}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ ...spring.soft, delay: i * 0.04 }}
              className="relative overflow-hidden rounded-xl border border-border/60 p-3 text-center"
              style={{
                background: `linear-gradient(180deg, ${meta.color}${Math.round(intensity * 40 + 8).toString(16).padStart(2, "0")}, transparent)`,
                boxShadow: n ? `0 0 ${12 + intensity * 24}px ${meta.glow}` : undefined,
              }}
            >
              <p className="font-mono text-lg font-semibold" style={{ color: meta.color }}>
                {n}
              </p>
              <p className="mt-1 text-[9px] uppercase tracking-wider text-muted-2">{meta.label}</p>
            </motion.div>
          );
        })}
      </div>
      <div className="mt-4 flex flex-wrap gap-1">
        {games.slice(0, 24).map((g, i) => {
          const kind = resolveGameStatus(g.status);
          const meta = status[kind];
          return (
            <motion.span
              key={g.id}
              title={`${g.name || g.id}: ${meta.label}`}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.015 }}
              className="h-3 w-3 rounded-sm"
              style={{ background: meta.color, boxShadow: `0 0 6px ${meta.glow}` }}
            />
          );
        })}
      </div>
    </div>
  );
}
