"use client";

import { useState } from "react";
import { ChevronDown, HelpCircle } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import type { FaqItem } from "@/lib/types";
import { SectionHeader } from "./SectionHeader";

const fallback: FaqItem[] = [
  {
    q: "How do I load Alleral?",
    a: "Copy the bootstrap loadstring from this page, save it once in your executor, and run it in a supported game.",
  },
  {
    q: "Does it auto-update?",
    a: "Yes. The loader polls GitHub every ~45 seconds and reloads when a new release is pinned.",
  },
  {
    q: "Which games work?",
    a: "Check the Games section — scripts only load when status is Working or Testing.",
  },
];

export function FAQSection({ items }: { items?: FaqItem[] }) {
  const faqs = (items?.length ? items : fallback).slice(0, 8);
  const [open, setOpen] = useState(0);

  return (
    <section id="faq" className="section-pad mx-auto max-w-3xl">
      <SectionHeader
        kicker="FAQ"
        icon={HelpCircle}
        title="Quick answers before you inject."
      />

      <div className="mt-10 space-y-3">
        {faqs.map((item, i) => {
          const active = open === i;
          return (
            <div key={item.q} className="surface-card overflow-hidden">
              <button
                type="button"
                className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
                onClick={() => setOpen(active ? -1 : i)}
              >
                <span className="font-medium text-text">{item.q}</span>
                <ChevronDown
                  className={`h-4 w-4 shrink-0 text-muted transition ${active ? "rotate-180 text-violet-bright" : ""}`}
                />
              </button>
              <AnimatePresence initial={false}>
                {active ? (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: "auto", opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.25 }}
                  >
                    <p className="border-t border-white/6 px-5 py-4 text-sm leading-7 text-muted">{item.a}</p>
                  </motion.div>
                ) : null}
              </AnimatePresence>
            </div>
          );
        })}
      </div>
    </section>
  );
}