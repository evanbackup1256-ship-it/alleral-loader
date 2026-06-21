"use client";

import { motion } from "framer-motion";
import { GitBranch, Server, ShieldCheck, Zap } from "lucide-react";
import { CodeTerminal } from "./CodeTerminal";
import { SectionHeader } from "./SectionHeader";

const steps = [
  {
    step: "01",
    title: "Fetch bootstrap",
    body: "Loader pulls the pinned bootstrap from GitHub with cache-busting tick.",
    icon: GitBranch,
  },
  {
    step: "02",
    title: "Verify release",
    body: "Core, UI, and game modules match the remote release manifest.",
    icon: ShieldCheck,
  },
  {
    step: "03",
    title: "Compose runtime",
    body: "WindUI hub, helpers, and the correct game script assemble in order.",
    icon: Server,
  },
  {
    step: "04",
    title: "Launch in-game",
    body: "RightShift opens the hub — configs, toggles, and live stats ready.",
    icon: Zap,
  },
];

export function PipelineSection({ loadstring }: { loadstring?: string }) {
  return (
    <section id="pipeline" className="section-pad mx-auto max-w-6xl">
      <SectionHeader
        kicker="Deployment pipeline"
        icon={GitBranch}
        title="Every release follows a verified path."
        description="Fetch, verify, compose, and launch — each stage gates the next."
      />

      <div className="mt-14 grid gap-8 lg:grid-cols-[1fr_1.05fr]">
        <motion.div
          className="surface-card p-5 md:p-6"
          initial={{ opacity: 0, x: -16 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.55 }}
        >
          <CodeTerminal loadstring={loadstring} />
        </motion.div>

        <div className="space-y-6">
          {steps.map((item, i) => (
            <motion.div
              key={item.step}
              className="pipeline-step surface-card p-5"
              data-step={item.step}
              initial={{ opacity: 0, x: 16 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: i * 0.08 }}
            >
              <div className="flex items-center gap-3">
                <item.icon className="h-4 w-4 text-violet-bright" />
                <h3 className="display-md">{item.title}</h3>
              </div>
              <p className="mt-2 text-sm leading-6 text-muted">{item.body}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}