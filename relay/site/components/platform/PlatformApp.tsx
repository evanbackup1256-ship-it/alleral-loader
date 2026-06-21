"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Terminal } from "lucide-react";
import { toast } from "sonner";
import { postHubVisit } from "@/lib/api";
import type { GameEntry, SitePayload } from "@/lib/types";
import { useLiveSyncMeta, useSiteQuery } from "@/lib/queries/hooks";
import { formatFreshness, resolveRelayStatus } from "@/lib/status/resolve";
import { useSecondsSince } from "@/lib/hooks/useSecondsSince";
import { CloudflareGate } from "@/components/gate/CloudflareGate";
import { QueryProvider } from "@/components/providers/QueryProvider";
import { SITE_SNAPSHOT } from "@/lib/site-snapshot";
import { SupportForm } from "@/components/support/SupportForm";
import { Ambient } from "@/components/landing/Ambient";
import { Navbar } from "@/components/landing/Navbar";
import { Hero } from "@/components/landing/Hero";
import { OverviewSection } from "@/components/landing/OverviewSection";
import { GamesSection } from "@/components/landing/GamesSection";
import { PipelineSection } from "@/components/landing/PipelineSection";
import { FAQSection } from "@/components/landing/FAQSection";
import { ChangelogSection } from "@/components/landing/ChangelogSection";
import { Footer } from "@/components/landing/Footer";
import { AdminModal } from "@/components/landing/AdminModal";
import { SectionHeader } from "@/components/landing/SectionHeader";

function getGameEntries(site: SitePayload): GameEntry[] {
  return Object.values(site.games || {})
    .filter(Boolean)
    .slice(0, 9);
}

function AlleralSite({
  site,
  online,
  siteUpdatedAt,
  siteFetching,
  onRefreshSite,
}: {
  site: SitePayload;
  online?: boolean;
  siteUpdatedAt?: number;
  siteFetching?: boolean;
  onRefreshSite?: () => void;
}) {
  const live = useLiveSyncMeta("overview");
  const siteAge = useSecondsSince(siteUpdatedAt ?? null, 1000);
  const games = useMemo(() => getGameEntries(site), [site]);
  const relayKind = resolveRelayStatus(online);
  const latestChange = site.changelog?.[0];

  const [adminPass, setAdminPass] = useState("");
  const [adminAuthed, setAdminAuthed] = useState(false);
  const [showAdminModal, setShowAdminModal] = useState(false);

  useEffect(() => {
    if (typeof window !== "undefined" && sessionStorage.getItem("alleral_admin_auth") === "true") {
      setAdminAuthed(true);
    }
  }, []);

  const copyLoadstring = useCallback(async () => {
    if (!site.loadstring) {
      toast.error("Loader unavailable");
      return;
    }
    try {
      await navigator.clipboard.writeText(site.loadstring);
      toast.success("Loader copied");
    } catch {
      toast.error("Copy failed");
    }
  }, [site.loadstring]);

  const refreshAll = useCallback(() => {
    onRefreshSite?.();
    void live.refresh();
    toast.message("Refreshing live signal");
  }, [live, onRefreshSite]);

  const handleAdminLogin = useCallback(() => {
    if (adminPass === "583716465") {
      sessionStorage.setItem("alleral_admin_auth", "true");
      setAdminAuthed(true);
      setShowAdminModal(false);
      setAdminPass("");
      toast.success("Admin authenticated");
    } else {
      toast.error("Invalid password");
    }
  }, [adminPass]);

  const openAdmin = useCallback(() => {
    if (adminAuthed) {
      window.open(site.links?.admin || `${site.links?.relay || ""}/admin.html`, "_blank");
    } else {
      setShowAdminModal(true);
    }
  }, [adminAuthed, site.links]);

  const uiLibrary = site.uiLibrary === "Linoria" || site.uiLibrary === "Fluent" ? "WindUI" : site.uiLibrary || "WindUI";
  const uiVersion = site.uiVersion || "11.6.0";

  return (
    <main className="page-wrap min-h-dvh text-text">
      <Ambient />
      <div className="relative z-10">
        <Navbar
          brand={site.brand || "Alleral"}
          freshness={formatFreshness(siteAge)}
          syncing={siteFetching}
          onCopy={copyLoadstring}
          onAdmin={openAdmin}
        />

        <Hero
          tagline={site.tagline}
          uiLibrary={uiLibrary}
          uiVersion={uiVersion}
          loaderVersion={site.loaderVersion}
          relayLive={relayKind === "online"}
          loadstring={site.loadstring}
          githubUrl={site.links?.github || site.links?.loaderRaw}
          onCopy={copyLoadstring}
        />

        <div className="divider-glow" />

        <OverviewSection
          relay={relayKind}
          freshness={formatFreshness(siteAge)}
          coreVersion={site.coreVersion}
          loaderVersion={site.loaderVersion}
        />

        <GamesSection games={games} />

        <PipelineSection loadstring={site.loadstring} />

        <section id="support" className="section-pad mx-auto max-w-3xl">
          <SectionHeader
            kicker="Support"
            icon={Terminal}
            title="Report issues to the ops channel."
            description="Submit a ticket and we'll follow up on Discord within 24 hours."
          />
          <div className="mt-10">
            <SupportForm />
          </div>
        </section>

        <FAQSection items={site.faq} />

        <ChangelogSection
          title={latestChange?.title}
          items={latestChange?.items}
          onCopy={copyLoadstring}
          mirrorUrl={site.links?.mirror || site.links?.website}
        />

        <Footer loaderVersion={site.loaderVersion} onAdmin={openAdmin} />
      </div>

      <AdminModal
        open={showAdminModal}
        password={adminPass}
        onPassword={setAdminPass}
        onClose={() => setShowAdminModal(false)}
        onSubmit={handleAdminLogin}
      />

      <button
        type="button"
        className="sr-only"
        onClick={refreshAll}
        aria-hidden
        tabIndex={-1}
      />
    </main>
  );
}

function PlatformAppInner() {
  const siteQuery = useSiteQuery();
  const site = siteQuery.data ?? SITE_SNAPSHOT;
  const liveQuery = useLiveSyncMeta("overview");

  useEffect(() => {
    void postHubVisit("website-rewrite-v2");
  }, []);

  const online = siteQuery.isError ? false : !liveQuery.error && liveQuery.data?.ok !== false;

  return (
    <CloudflareGate>
      <AlleralSite
        site={site}
        online={online}
        siteUpdatedAt={siteQuery.dataUpdatedAt}
        siteFetching={siteQuery.isFetching}
        onRefreshSite={() => void siteQuery.refetch()}
      />
    </CloudflareGate>
  );
}

export function PlatformApp() {
  return (
    <QueryProvider>
      <PlatformAppInner />
    </QueryProvider>
  );
}