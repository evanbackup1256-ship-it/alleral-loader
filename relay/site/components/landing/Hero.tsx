"use client";

import { motion } from "framer-motion";
import { ArrowRight, ChevronRight, GitBranch, Rocket, Sparkles } from "lucide-react";
import { CodeTerminal } from "./CodeTerminal";

export function Hero({
  tagline,
  uiLibrary,
  uiVersion,
  loaderVersion,
  relayLive,
  loadstring,
  githubUrl,
  onCopy,
}: {
  tagline?: string;
  uiLibrary?: string;
  uiVersion?: string;
  loaderVersion?: string;
  relayLive?: boolean;
  loadstring?: string;
  githubUrl?: string;
  onCopy: () => void;
}) {
  return (
    <section
      id="top"
      className="relative mx-auto grid min-h-[92dvh] max-w-6xl items-center gap-12 px-4 pb-20 pt-28 md:grid-cols-[1.05fr_0.95fr] md:px-6 md:pt-32"
    >
      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
      >
        <div className="kicker">
          <Sparkles className="h-3.5 w-3.5" />
          {relayLive ? "Relay online" : "Relay monitored"} · {uiLibrary || "WindUI"} {uiVersion || "11.6"}
        </div>

        <h1 className="display-xl mt-8">
          Scripts that <span className="gradient-headline">stay fresh</span> after one inject.
        </h1>

        <p className="mt-6 max-w-xl text-lg leading-8 text-muted md:text-xl">
          {tagline ||
            "One bootstrap loadstring, live game routing, automatic GitHub pins, and a premium WindUI hub."}
        </p>

        <div className="mt-8 flex flex-col gap-3 sm:flex-row">
          <button type="button" className="btn btn-primary" onClick={onCopy}>
            <Rocket className="h-4 w-4" />
            Copy loader
            <ChevronRight className="h-4 w-4" />
          </button>
          <a
            className="btn btn-secondary"
            href={githubUrl || "#pipeline"}
            target="_blank"
            rel="noreferrer"
          >
            <GitBranch className="h-4 w-4" />
            View source
            <ArrowRight className="h-4 w-4" />
          </a>
        </div>

        <div className="mt-10 grid gap-3 sm:grid-cols-3">
          {[
            { label: "Loader", value: loaderVersion || "8.12" },
            { label: "UI", value: uiLibrary || "WindUI" },
            { label: "Poll", value: "~45s" },
          ].map((stat) => (
            <div
              key={stat.label}
              className="rounded-xl border border-white/6 bg-white/[0.02] px-4 py-3"
            >
              <p className="font-mono text-[10px] uppercase tracking-wider text-muted-2">{stat.label}</p>
              <p className="mt-1 text-lg font-semibold text-text-strong">{stat.value}</p>
            </div>
          ))}
        </div>
      </motion.div>

      <motion.div
        className="relative"
        initial={{ opacity: 0, y: 28 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.75, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
      >
        <div className="absolute -inset-4 rounded-[28px] bg-gradient-to-br from-violet/20 via-transparent to-cyan/15 blur-2xl" />
        <div className="surface-card float-soft relative p-5 md:p-6">
          <div className="mb-4 flex items-center justify-between">
            <p className="font-mono text-[10px] uppercase tracking-wider text-muted-2">Runtime profile</p>
            <span className="badge badge-live">stable</span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="rounded-xl border border-white/6 bg-void/50 p-4">
              <p className="text-xs text-muted">Visible UI</p>
              <p className="mt-2 text-2xl font-bold text-text-strong">{uiLibrary || "WindUI"}</p>
            </div>
            <div className="rounded-xl border border-white/6 bg-void/50 p-4">
              <p className="text-xs text-muted">Motion</p>
              <p className="mt-2 text-2xl font-bold text-text-strong">Native</p>
            </div>
          </div>
          <ul className="mt-4 space-y-2 text-sm text-muted">
            {[
              "EXE-6 glass panels",
              "Live release pins",
              "Single config profile",
              "WEAO executor intel",
            ].map((item) => (
              <li key={item} className="flex items-center gap-2 rounded-lg bg-white/[0.02] px-3 py-2">
                <span className="h-1.5 w-1.5 rounded-full bg-cyan" />
                {item}
              </li>
            ))}
          </ul>
        </div>
        <div className="relative mt-4">
          <CodeTerminal loadstring={loadstring} />
        </div>
      </motion.div>
    </section>
  );
}