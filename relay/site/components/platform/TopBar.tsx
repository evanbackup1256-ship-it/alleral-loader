"use client";

import { Search } from "lucide-react";
import { Button, Kbd } from "@/components/ui/Button";
import { Select } from "@/components/ui/Form";
import { FreshnessChip } from "@/components/observability/FreshnessChip";
import { StatusPill } from "@/components/observability/StatusPill";
import { resolveRelayStatus } from "@/lib/status/resolve";
import { usePlatformStore, VIEW_META, type WorkspacePreset } from "@/lib/store/platform";

const WORKSPACE_OPTIONS: { value: WorkspacePreset; label: string }[] = [
  { value: "default", label: "Default workspace" },
  { value: "compact", label: "Compact density" },
  { value: "wide", label: "Wide analytics" },
];

export function TopBar({
  online,
  workspace,
  secondsAgo,
}: {
  online?: boolean;
  workspace: string;
  secondsAgo?: number | null;
}) {
  const setOpen = usePlatformStore((s) => s.setCommandOpen);
  const activeView = usePlatformStore((s) => s.activeView);
  const setWorkspace = usePlatformStore((s) => s.setWorkspace);
  const preset = (WORKSPACE_OPTIONS.some((o) => o.value === workspace) ? workspace : "default") as WorkspacePreset;
  const relayKind = resolveRelayStatus(online);

  return (
    <header className="glass-panel z-20 flex h-[3.75rem] shrink-0 items-center justify-between border-b border-border px-4 md:px-5">
      <div className="min-w-0">
        <p className="obs-kicker !text-[10px]">Workspace · {preset}</p>
        <h1 className="truncate text-base font-semibold tracking-tight">{VIEW_META[activeView].label}</h1>
      </div>

      <div className="flex items-center gap-2 md:gap-3">
        <FreshnessChip secondsAgo={secondsAgo ?? null} live={online !== false} className="hidden sm:inline-flex" />
        <StatusPill kind={relayKind} size="sm" pulse={online !== false} className="hidden md:inline-flex" />
        <div className="hidden w-44 lg:block">
          <Select name="workspace" options={WORKSPACE_OPTIONS} value={preset} onChange={(v) => setWorkspace(v as WorkspacePreset)} />
        </div>
        <Button variant="ghost" size="sm" onClick={() => setOpen(true)} className="gap-2">
          <Search className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">Command</span>
          <Kbd>⌘K</Kbd>
        </Button>
      </div>
    </header>
  );
}
