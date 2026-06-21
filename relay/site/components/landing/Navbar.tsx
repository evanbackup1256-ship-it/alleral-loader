"use client";

import { useState } from "react";
import { Clipboard, Menu, Shield, Sparkles, X } from "lucide-react";

const links = [
  { label: "Overview", href: "#overview" },
  { label: "Games", href: "#games" },
  { label: "Pipeline", href: "#pipeline" },
  { label: "FAQ", href: "#faq" },
  { label: "Support", href: "#support" },
];

export function Navbar({
  brand,
  freshness,
  syncing,
  onCopy,
  onAdmin,
}: {
  brand: string;
  freshness: string;
  syncing?: boolean;
  onCopy: () => void;
  onAdmin: () => void;
}) {
  const [open, setOpen] = useState(false);

  return (
    <header className="fixed inset-x-0 top-0 z-50 glass-nav">
      <nav className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 md:px-6">
        <a href="#top" className="flex items-center gap-3">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl border border-violet/30 bg-violet/10 text-violet-bright">
            <Sparkles className="h-4 w-4" />
          </span>
          <span className="hidden sm:block">
            <strong className="block text-sm font-semibold leading-none text-text-strong">{brand}</strong>
            <span className="font-mono text-[10px] uppercase tracking-wider text-muted-2">WindUI runtime</span>
          </span>
        </a>

        <div className="hidden items-center gap-7 md:flex">
          {links.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="text-sm text-muted transition hover:text-text"
            >
              {item.label}
            </a>
          ))}
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            className="hidden rounded-lg border border-white/8 bg-white/[0.03] px-3 py-2 font-mono text-[11px] text-muted transition hover:text-text md:inline-flex"
            onClick={onCopy}
          >
            {syncing ? "Syncing…" : freshness}
          </button>
          <button type="button" className="btn btn-primary hidden sm:inline-flex" onClick={onCopy}>
            <Clipboard className="h-4 w-4" />
            Copy loader
          </button>
          <button
            type="button"
            className="hidden rounded-lg border border-white/8 p-2 text-muted transition hover:text-text md:inline-flex"
            onClick={onAdmin}
            aria-label="Admin"
          >
            <Shield className="h-4 w-4" />
          </button>
          <button
            type="button"
            className="rounded-lg p-2 text-muted transition hover:text-text md:hidden"
            onClick={() => setOpen((v) => !v)}
            aria-label="Menu"
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </nav>

      {open ? (
        <div className="border-t border-white/6 bg-void/95 backdrop-blur-xl md:hidden">
          <div className="flex flex-col gap-1 px-4 py-4">
            {links.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="rounded-lg px-3 py-2.5 text-sm text-muted transition hover:bg-white/[0.03] hover:text-text"
                onClick={() => setOpen(false)}
              >
                {item.label}
              </a>
            ))}
            <button type="button" className="btn btn-primary mt-2" onClick={() => { setOpen(false); onCopy(); }}>
              Copy loader
            </button>
          </div>
        </div>
      ) : null}
    </header>
  );
}