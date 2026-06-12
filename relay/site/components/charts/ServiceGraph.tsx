"use client";

import clsx from "clsx";
import { motion } from "motion/react";
import { resolveGameStatus } from "@/lib/status/resolve";
import { status } from "@/lib/design/tokens";
import { spring } from "@/lib/motion/config";

export function ServiceGraph({
  games,
  className,
}: {
  games: { id: string; name?: string; status?: string }[];
  className?: string;
}) {
  const hub = { id: "relay", name: "Alleral Relay", kind: "online" as const };

  return (
    <div className={clsx("obs-panel", className)}>
      <div className="obs-panel-head">
        <div>
          <p className="obs-kicker">Dependency graph</p>
          <h3 className="obs-title-sm">Hub → scripts</h3>
        </div>
      </div>
      <div className="relative mt-4 h-[calc(100%-3rem)] min-h-[140px]">
        <svg className="absolute inset-0 h-full w-full" aria-hidden>
          {games.map((g, i) => {
            const angle = (i / Math.max(games.length, 1)) * Math.PI * 1.6 - Math.PI * 0.8;
            const x2 = 50 + Math.cos(angle) * 38;
            const y2 = 55 + Math.sin(angle) * 32;
            return (
              <line
                key={g.id}
                x1="50%"
                y1="28%"
                x2={`${x2}%`}
                y2={`${y2}%`}
                stroke="rgba(34,211,238,0.18)"
                strokeWidth="1"
              />
            );
          })}
        </svg>

        <motion.div
          className="absolute left-1/2 top-[18%] -translate-x-1/2 rounded-xl border px-3 py-2 text-center"
          style={{
            borderColor: `${status[hub.kind].color}44`,
            background: `${status[hub.kind].color}12`,
            boxShadow: `0 0 20px ${status[hub.kind].glow}`,
          }}
          animate={{ y: [0, -3, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
        >
          <p className="text-[10px] font-semibold text-text">{hub.name}</p>
          <p className="text-[9px] text-muted">Hub</p>
        </motion.div>

        {games.map((g, i) => {
          const kind = resolveGameStatus(g.status);
          const meta = status[kind];
          const angle = (i / Math.max(games.length, 1)) * Math.PI * 1.6 - Math.PI * 0.8;
          const left = 50 + Math.cos(angle) * 38;
          const top = 55 + Math.sin(angle) * 32;
          return (
            <motion.div
              key={g.id}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ ...spring.soft, delay: 0.1 + i * 0.04 }}
              className="absolute -translate-x-1/2 -translate-y-1/2 rounded-lg border px-2 py-1.5 text-center"
              style={{
                left: `${left}%`,
                top: `${top}%`,
                borderColor: `${meta.color}33`,
                background: `${meta.color}10`,
                boxShadow: `0 0 12px ${meta.glow}`,
              }}
            >
              <p className="max-w-[72px] truncate text-[9px] font-medium text-text">{g.name || g.id}</p>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
