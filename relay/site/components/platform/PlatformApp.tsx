"use client";

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useState } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { toast } from "sonner";
import { fetchSite, postHubVisit } from "@/lib/api";
import type { SitePayload } from "@/lib/types";
import { usePlatformStore, type PlatformView } from "@/lib/store/platform";
import { useHubStatus } from "@/lib/hooks/useHubStatus";
import { reveal, spring } from "@/lib/motion/config";
import { CloudflareGate } from "@/components/gate/CloudflareGate";
import { MeshBackground } from "@/components/background/MeshBackground";
import { AmbientScene } from "@/components/platform/AmbientScene";
import { CommandPalette } from "@/components/platform/CommandPalette";
import { Sidebar } from "@/components/platform/Sidebar";
import { TopBar } from "@/components/platform/TopBar";
import { OverviewView } from "@/components/views/OverviewView";
import { StatusView } from "@/components/views/StatusView";
import { GamesView } from "@/components/views/GamesView";
import { ToolsView } from "@/components/views/ToolsView";
import { ChangelogView } from "@/components/views/ChangelogView";
import { SupportView } from "@/components/views/SupportView";
import { CreditsView } from "@/components/views/CreditsView";
import { LenisProvider } from "@/components/providers/LenisProvider";

gsap.registerPlugin(ScrollTrigger);

export function PlatformApp() {
  const [site, setSite] = useState<SitePayload | null>(null);
  const [online, setOnline] = useState<boolean | undefined>();
  const activeView = usePlatformStore((s) => s.activeView);
  const workspace = usePlatformStore((s) => s.workspace);
  const { secondsAgo, refresh: refreshLive } = useHubStatus(15000);

  const load = useCallback(async () => {
    try {
      const data = await fetchSite();
      setSite(data);
      setOnline(true);
    } catch {
      setOnline(false);
    }
  }, []);

  useEffect(() => {
    void load();
    void postHubVisit();
    const t = setInterval(load, 30000);
    return () => clearInterval(t);
  }, [load]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const tag = (e.target as HTMLElement | null)?.tagName;
      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;
      const map: Record<string, PlatformView> = {
        o: "overview",
        l: "status",
        g: "games",
        e: "tools",
        h: "changelog",
        s: "support",
        t: "credits",
      };
      const next = map[e.key.toLowerCase()];
      if (next) usePlatformStore.getState().setView(next);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const copyLoadstring = async () => {
    if (!site?.loadstring) return;
    try {
      await navigator.clipboard.writeText(site.loadstring);
      toast.success("Loader copied to clipboard");
    } catch {
      toast.error("Copy failed");
    }
  };

  if (!site) {
    return (
      <div className="grid min-h-screen place-items-center">
        <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} transition={spring.soft} className="glass-float rounded-2xl px-8 py-6 text-center">
          <p className="text-sm text-muted">Initializing observability platform…</p>
        </motion.div>
      </div>
    );
  }

  const mainPad = workspace === "compact" ? "p-3 md:p-4" : workspace === "wide" ? "p-5 md:p-8" : "p-4 md:p-6";

  return (
    <LenisProvider>
      <CloudflareGate>
        <MeshBackground />
        <AmbientScene />
        <div className="noise-overlay" aria-hidden />
        <div className="ambient-orb left-[-10%] top-[-20%] h-[420px] w-[420px] bg-indigo-500/20" aria-hidden />
        <div className="ambient-orb right-[-5%] top-[10%] h-[360px] w-[360px] bg-cyan-400/15" aria-hidden />

        <div className="relative z-10 flex min-h-screen">
          <Sidebar online={online} />
          <div className="flex min-w-0 flex-1 flex-col">
            <TopBar online={online} workspace={workspace} secondsAgo={secondsAgo} />
            <main className={`flex-1 overflow-y-auto obs-scroll ${mainPad}`}>
              <AnimatePresence mode="wait">
                <motion.div
                  key={activeView}
                  initial={reveal.initial}
                  animate={reveal.animate}
                  exit={reveal.exit}
                  transition={spring.panel}
                  className={`mx-auto w-full max-w-[1520px] ${workspace === "wide" ? "max-w-[1680px]" : ""}`}
                >
                  {activeView === "overview" ? <OverviewView site={site} online={online} onCopy={() => void copyLoadstring()} /> : null}
                  {activeView === "status" ? <StatusView site={site} /> : null}
                  {activeView === "games" ? <GamesView site={site} /> : null}
                  {activeView === "tools" ? <ToolsView site={site} /> : null}
                  {activeView === "changelog" ? <ChangelogView site={site} /> : null}
                  {activeView === "support" ? <SupportView site={site} /> : null}
                  {activeView === "credits" ? <CreditsView site={site} /> : null}
                </motion.div>
              </AnimatePresence>
            </main>
          </div>
        </div>
        <CommandPalette
          onCopyScript={() => void copyLoadstring()}
          onRefresh={() => {
            void load();
            void refreshLive();
            toast.message("Refreshing telemetry");
          }}
        />
      </CloudflareGate>
    </LenisProvider>
  );
}
