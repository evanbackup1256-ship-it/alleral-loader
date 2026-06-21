"use client";

import { Clipboard } from "lucide-react";
import { toast } from "sonner";

export function CodeTerminal({ loadstring }: { loadstring?: string }) {
  const code =
    loadstring ||
    'loadstring(game:HttpGet("https://raw.githubusercontent.com/.../bootstrap.luau"))()';

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      toast.success("Loader copied");
    } catch {
      toast.error("Copy failed");
    }
  };

  return (
    <div className="terminal">
      <div className="flex items-center justify-between border-b border-white/8 px-4 py-3">
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-red" />
          <span className="h-2.5 w-2.5 rounded-full bg-yellow" />
          <span className="h-2.5 w-2.5 rounded-full bg-green" />
        </div>
        <span className="font-mono text-[10px] uppercase tracking-wider text-muted-2">
          alleral/bootstrap.luau
        </span>
        <button
          type="button"
          onClick={copy}
          className="rounded-lg border border-white/10 p-1.5 text-muted transition hover:border-violet/30 hover:text-text"
          aria-label="Copy loader"
        >
          <Clipboard className="h-3.5 w-3.5" />
        </button>
      </div>
      <pre className="overflow-x-auto whitespace-pre-wrap px-4 py-5 text-cyan-bright">
        <span className="text-muted-2">-- pinned entrypoint</span>
        {"\n"}
        {code}
      </pre>
      <div className="grid grid-cols-3 border-t border-white/8 text-center font-mono text-[10px] uppercase tracking-wider text-muted-2">
        <span className="px-3 py-3">fetch</span>
        <span className="border-x border-white/8 px-3 py-3">verify</span>
        <span className="px-3 py-3">launch</span>
      </div>
    </div>
  );
}