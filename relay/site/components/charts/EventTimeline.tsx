"use client";

import clsx from "clsx";
import { motion } from "motion/react";
import { spring } from "@/lib/motion/config";
import { StatusPill } from "@/components/observability/StatusPill";
import { resolveGameStatus } from "@/lib/status/resolve";

export function EventTimeline({
  events,
  className,
}: {
  events: { at?: string; title?: string; detail?: string; kind?: "release" | "sync" | "status" }[];
  className?: string;
}) {
  return (
    <div className={clsx("obs-panel flex h-full min-h-0 flex-col", className)}>
      <div className="obs-panel-head shrink-0">
        <div>
          <p className="obs-kicker">Event timeline</p>
          <h3 className="obs-title-sm">Activity stream</h3>
        </div>
      </div>
      <div className="mt-3 min-h-0 flex-1 space-y-0 overflow-y-auto pr-1 obs-scroll">
        {events.length ? (
          events.map((ev, i) => (
            <motion.div
              key={`${ev.at}-${i}`}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ ...spring.soft, delay: Math.min(i * 0.03, 0.25) }}
              className="relative flex gap-3 pb-4 pl-4 last:pb-0"
            >
              <span className="absolute left-0 top-1.5 h-full w-px bg-gradient-to-b from-cyan-400/50 to-transparent" />
              <span className="absolute left-[-3px] top-1.5 h-2 w-2 rounded-full border border-cyan-400/60 bg-cyan-400/30 shadow-[0_0_8px_rgba(34,211,238,0.5)]" />
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <StatusPill kind={ev.kind === "sync" ? "syncing" : ev.kind === "status" ? "warning" : "online"} size="sm" label={ev.kind || "event"} />
                  <time className="font-mono text-[10px] text-muted-2">{ev.at || "—"}</time>
                </div>
                <p className="mt-1 text-sm font-medium text-text">{ev.title || "Update"}</p>
                {ev.detail ? <p className="mt-0.5 text-xs text-muted">{ev.detail}</p> : null}
              </div>
            </motion.div>
          ))
        ) : (
          <p className="text-sm text-muted-2">Waiting for activity…</p>
        )}
      </div>
    </div>
  );
}

export function GameStatusStream({
  games,
  className,
}: {
  games: { id: string; name?: string; status?: string; message?: string; version?: string }[];
  className?: string;
}) {
  return (
    <div className={clsx("obs-panel flex h-full min-h-0 flex-col", className)}>
      <div className="obs-panel-head shrink-0">
        <div>
          <p className="obs-kicker">Service map</p>
          <h3 className="obs-title-sm">Script endpoints</h3>
        </div>
      </div>
      <div className="mt-2 min-h-0 flex-1 space-y-1.5 overflow-y-auto obs-scroll">
        {games.map((g, i) => {
          const kind = resolveGameStatus(g.status);
          return (
            <motion.div
              key={g.id}
              layout
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ ...spring.layout, delay: Math.min(i * 0.02, 0.2) }}
              className="group flex items-center justify-between gap-3 rounded-xl border border-border/70 bg-black/20 px-3 py-2.5 transition hover:border-cyan-400/25 hover:bg-cyan-400/[0.04]"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-medium">{g.name || g.id}</p>
                <p className="truncate text-[11px] text-muted">{g.message || "Operational"}</p>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                {g.version ? <span className="font-mono text-[10px] text-muted-2">v{g.version}</span> : null}
                <StatusPill kind={kind} size="sm" pulse={kind === "healthy"} />
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
