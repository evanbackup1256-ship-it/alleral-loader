"use client";

import { motion } from "framer-motion";
import { BadgeCheck, Clipboard, Network, ScrollText } from "lucide-react";
export function ChangelogSection({
  title,
  items,
  onCopy,
  mirrorUrl,
}: {
  title?: string;
  items?: string[];
  onCopy: () => void;
  mirrorUrl?: string;
}) {
  const list = (items?.length ? items : [
    "WindUI v11.6 EXE-6 polish",
    "Opaque glass panels",
    "Live release pins",
    "Sell Lemons runtime fix",
    "WEAO executor intel",
    "Auto-update polling",
  ]).slice(0, 6);

  return (
    <section id="access" className="section-pad mx-auto max-w-6xl pb-28">
      <div className="grid gap-4 lg:grid-cols-[1.1fr_0.9fr]">
        <motion.div
          className="surface-card p-6 md:p-8"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          <div className="kicker">
            <ScrollText className="h-3.5 w-3.5" />
            Latest changes
          </div>
          <h2 className="display-lg mt-6">
            {title || "Built for fast fixes and clear releases."}
          </h2>
          <div className="mt-8 grid gap-3 md:grid-cols-2">
            {list.map((item) => (
              <div key={item} className="flex gap-3 rounded-xl border border-white/6 bg-void/40 p-3">
                <BadgeCheck className="mt-0.5 h-4 w-4 shrink-0 text-violet-bright" />
                <span className="text-sm leading-6 text-muted">{item}</span>
              </div>
            ))}
          </div>
        </motion.div>

        <motion.div
          className="surface-card flex flex-col justify-between p-6 md:p-8"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.08 }}
        >
          <div>
            <div className="kicker">Launch</div>
            <h2 className="display-lg mt-5">One command. Full hub.</h2>
            <p className="mt-3 text-sm leading-7 text-muted">
              Copy the live loader and let release routing pick the right game module and UI stack.
            </p>
          </div>
          <div className="mt-8 flex flex-col gap-3">
            <button type="button" className="btn btn-primary" onClick={onCopy}>
              <Clipboard className="h-4 w-4" />
              Copy loadstring
            </button>
            <a className="btn btn-ghost" href={mirrorUrl || "#top"} target="_blank" rel="noreferrer">
              <Network className="h-4 w-4" />
              Open mirror
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  );
}