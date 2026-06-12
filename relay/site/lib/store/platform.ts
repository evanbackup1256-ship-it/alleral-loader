import { create } from "zustand";
import { persist } from "zustand/middleware";

export type PlatformView =
  | "overview"
  | "status"
  | "games"
  | "tools"
  | "changelog"
  | "support"
  | "credits";

export type WorkspacePreset = "default" | "compact" | "wide";

interface PlatformState {
  activeView: PlatformView;
  sidebarCollapsed: boolean;
  commandOpen: boolean;
  workspace: WorkspacePreset;
  setView: (view: PlatformView) => void;
  toggleSidebar: () => void;
  setCommandOpen: (open: boolean) => void;
  setWorkspace: (workspace: WorkspacePreset) => void;
}

export const usePlatformStore = create<PlatformState>()(
  persist(
    (set) => ({
      activeView: "overview",
      sidebarCollapsed: false,
      commandOpen: false,
      workspace: "default",
      setView: (activeView) => set({ activeView }),
      toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
      setCommandOpen: (commandOpen) => set({ commandOpen }),
      setWorkspace: (workspace) => {
        const raw = String(workspace);
        const next: WorkspacePreset =
          raw === "compact" || raw === "wide" ? raw : "default";
        set({ workspace: next });
      },
    }),
    { name: "alleral-platform", partialize: (s) => ({ sidebarCollapsed: s.sidebarCollapsed, workspace: s.workspace }) }
  )
);

export const VIEW_META: Record<PlatformView, { label: string; shortcut: string; desc: string }> = {
  overview: { label: "Overview", shortcut: "O", desc: "Platform summary and loader" },
  status: { label: "Mission Control", shortcut: "L", desc: "Observability command center" },
  games: { label: "Games", shortcut: "G", desc: "Script library and status" },
  tools: { label: "Executors", shortcut: "E", desc: "WEAO exploit tracker" },
  changelog: { label: "Ship Log", shortcut: "H", desc: "Release history" },
  support: { label: "Support", shortcut: "S", desc: "Bug reports and contact" },
  credits: { label: "Team", shortcut: "T", desc: "Credits and contributors" },
};
