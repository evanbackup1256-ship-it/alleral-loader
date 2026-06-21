"use client";

import { motion } from "framer-motion";
import { Activity, Cpu, Gauge, Shield } from "lucide-react";
import { SectionHeader } from "./SectionHeader";

const cards = [
  {
    icon: Activity,
    title: "Relay",
    key: "relay",
    detail: "Live sync from the hub status endpoint.",
  },
  {
    icon: Gauge,
    title: "Freshness",
    key: "freshness",
    detail: "Static snapshot baked at build with live refresh.",
  },
  {
    icon: Cpu,
    title: "Core",
    key: "core",
    detail: "Loader + core modules pinned from GitHub releases.",
  },
  {
    icon: Shield,
    title: "Guardrails",
    key: "guard",
    detail: "Access and security layers load before game scripts.",
  },
] as const;

export function OverviewSection({
  relay,
  freshness,
  coreVersion,
  loaderVersion,
}: {
  relay: string;
  freshness: string;
  coreVersion?: string;
  loaderVersion?: string;
}) {
  const values: Record<string, string> = {
    relay,
    freshness,
    core: coreVersion || "2.9.10",
    guard: "public",
  };

  return (
    <section id="overview" className="section-pad relative mx-auto max-w-6xl">
      <SectionHeader
        kicker="Live overview"
        icon={Activity}
        title="Everything you need on one surface."
        description="Relay health, release pins, and runtime facts — no digging through dashboards."
      />

      <div className="mt-14 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {cards.map((card, i) => (
          <motion.article
            key={card.title}
            className="surface-card surface-card-hover p-5"
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-40px" }}
            transition={{ duration: 0.5, delay: i * 0.06 }}
          >
            <card.icon className="h-5 w-5 text-cyan" />
            <p className="mt-5 text-sm font-medium text-muted">{card.title}</p>
            <strong className="mt-2 block text-2xl font-bold tracking-tight text-text-strong">
              {values[card.key]}
            </strong>
            <p className="mt-3 text-sm leading-6 text-muted">
              {card.key === "core"
                ? `Loader ${loaderVersion || "8.12"} with automatic release polling.`
                : card.detail}
            </p>
          </motion.article>
        ))}
      </div>
    </section>
  );
}