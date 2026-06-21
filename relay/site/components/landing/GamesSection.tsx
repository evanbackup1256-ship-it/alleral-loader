"use client";

import { motion } from "framer-motion";
import { Gamepad2 } from "lucide-react";
import type { GameEntry } from "@/lib/types";
import { SectionHeader } from "./SectionHeader";

function statusBadge(status?: string) {
  const n = String(status || "").toLowerCase();
  if (n.includes("work") || n.includes("online") || n.includes("stable")) return "badge-live";
  if (n.includes("partial") || n.includes("test")) return "badge-warn";
  if (n.includes("down") || n.includes("broken")) return "badge-down";
  return "badge-live";
}

export function GamesSection({ games }: { games: GameEntry[] }) {
  const list = games.length
    ? games
    : [{ name: "Auto-selected experience", status: "tracked", description: "Place ID routing with live metadata." }];

  return (
    <section id="games" className="section-pad border-y border-white/6 bg-white/[0.015]">
      <div className="mx-auto max-w-6xl">
        <SectionHeader
          kicker="Game routing"
          icon={Gamepad2}
          title="Scripts that know where they landed."
          description="Supported experiences, live status, and feature tags — presented as a clean launch matrix."
          align="left"
        />

        <div className="mt-12 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {list.map((game, i) => {
            const features = (game.scriptFeatures || []).slice(0, 3);
            return (
              <motion.article
                key={game.id || game.name || i}
                className="surface-card surface-card-hover p-5"
                initial={{ opacity: 0, y: 18 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-30px" }}
                transition={{ duration: 0.45, delay: i * 0.05 }}
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-mono text-[10px] uppercase tracking-wider text-muted-2">
                      {game.version || "live script"}
                    </p>
                    <h3 className="mt-2 text-lg font-semibold text-text-strong">
                      {game.name || game.id || "Supported game"}
                    </h3>
                  </div>
                  <span className={`badge ${statusBadge(game.status)}`}>{game.status || "tracked"}</span>
                </div>
                <p className="mt-4 min-h-12 text-sm leading-6 text-muted">
                  {game.description ||
                    game.message ||
                    "Auto-selected by place ID with release metadata and health checks."}
                </p>
                <div className="mt-5 flex flex-wrap gap-2">
                  {(features.length
                    ? features
                    : [{ name: "Auto load" }, { name: "Config aware" }, { name: "Live pin" }]
                  ).map((f) => (
                    <span key={f.name} className="chip">
                      {f.name}
                    </span>
                  ))}
                </div>
              </motion.article>
            );
          })}
        </div>
      </div>
    </section>
  );
}