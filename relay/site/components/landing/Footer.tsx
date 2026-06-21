"use client";

import { Shield } from "lucide-react";

export function Footer({
  loaderVersion,
  onAdmin,
}: {
  loaderVersion?: string;
  onAdmin: () => void;
}) {
  return (
    <footer className="border-t border-white/6 px-4 py-10 md:px-6">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 sm:flex-row">
        <p className="font-mono text-xs text-muted-2">
          Alleral · loader {loaderVersion || "8.12"} · WindUI 11.6
        </p>
        <button
          type="button"
          className="inline-flex items-center gap-1.5 text-xs text-muted-2 transition hover:text-muted"
          onClick={onAdmin}
        >
          <Shield className="h-3.5 w-3.5" />
          Admin
        </button>
      </div>
    </footer>
  );
}