"use client";

import { Command } from "cmdk";
import { useEffect } from "react";
import { usePlatformStore, VIEW_META, type PlatformView } from "@/lib/store/platform";

export function CommandPalette({
  onCopyScript,
  onRefresh,
}: {
  onCopyScript?: () => void;
  onRefresh?: () => void;
}) {
  const open = usePlatformStore((s) => s.commandOpen);
  const setOpen = usePlatformStore((s) => s.setCommandOpen);
  const setView = usePlatformStore((s) => s.setView);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen(!open);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, setOpen]);

  const go = (view: PlatformView) => {
    setView(view);
    setOpen(false);
  };

  const views = Object.keys(VIEW_META) as PlatformView[];

  if (!open) return null;

  return (
    <>
      <button
        type="button"
        aria-label="Close command palette"
        className="fixed inset-0 z-[300] bg-black/70"
        onClick={() => setOpen(false)}
      />
      <div className="view-enter fixed left-1/2 top-[18%] z-[301] w-[min(640px,calc(100vw-24px))] -translate-x-1/2">
        <Command className="panel-raised overflow-hidden" label="Command palette">
          <div className="border-b border-border px-4 py-3">
            <Command.Input
              placeholder="Search views, actions, shortcuts…"
              className="w-full bg-transparent text-sm outline-none placeholder:text-muted"
            />
          </div>
          <Command.List className="max-h-[360px] overflow-y-auto overscroll-contain p-2 obs-scroll">
            <Command.Empty className="px-3 py-6 text-center text-sm text-muted">No results.</Command.Empty>
            <Command.Group heading="Navigate" className="px-2 py-1 text-[10px] uppercase tracking-wider text-muted-2">
              {views.map((view) => (
                <Command.Item
                  key={view}
                  onSelect={() => go(view)}
                  className="flex w-full cursor-pointer items-center justify-between rounded-xl px-3 py-2.5 text-left text-sm text-muted aria-selected:bg-white/[0.06] aria-selected:text-text"
                >
                  <span>{VIEW_META[view].label}</span>
                  <kbd className="font-mono text-[10px] text-muted-2">⌘{VIEW_META[view].shortcut}</kbd>
                </Command.Item>
              ))}
            </Command.Group>
            <Command.Group heading="Actions" className="px-2 py-1 text-[10px] uppercase tracking-wider text-muted-2">
              <Command.Item
                onSelect={() => {
                  onCopyScript?.();
                  setOpen(false);
                }}
                className="cursor-pointer rounded-xl px-3 py-2.5 text-sm text-muted aria-selected:bg-white/[0.06] aria-selected:text-text"
              >
                Copy loader script
              </Command.Item>
              <Command.Item
                onSelect={() => {
                  onRefresh?.();
                  setOpen(false);
                }}
                className="cursor-pointer rounded-xl px-3 py-2.5 text-sm text-muted aria-selected:bg-white/[0.06] aria-selected:text-text"
              >
                Refresh live data
              </Command.Item>
              <Command.Item
                onSelect={() => {
                  window.open("/admin", "_blank");
                  setOpen(false);
                }}
                className="cursor-pointer rounded-xl px-3 py-2.5 text-sm text-muted aria-selected:bg-white/[0.06] aria-selected:text-text"
              >
                Open admin panel
              </Command.Item>
            </Command.Group>
          </Command.List>
        </Command>
      </div>
    </>
  );
}
