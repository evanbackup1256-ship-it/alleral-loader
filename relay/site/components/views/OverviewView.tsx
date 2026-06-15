"use client";

import { ArrowRight, Check, Copy, ExternalLink, Gamepad2, Radio, Sparkles, Zap } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { MetricCard } from "@/components/observability/MetricCard";
import { StatusPill } from "@/components/observability/StatusPill";
import { FreshnessChip } from "@/components/observability/FreshnessChip";
import { useLiveSyncMeta } from "@/lib/queries/hooks";
import { resolveRelayStatus, resolveSyncStatus } from "@/lib/status/resolve";
import { resolveResourceUrl } from "@/lib/sanitize";
import type { SitePayload } from "@/lib/types";
import { usePlatformStore } from "@/lib/store/platform";

export function OverviewView({
  site,
  online,
  onCopy,
}: {
  site: SitePayload;
  online?: boolean;
  onCopy: () => void;
}) {
  const setView = usePlatformStore((s) => s.setView);
  const { data: live, dataUpdatedAt } = useLiveSyncMeta("overview");
  const games = Object.entries(site.games || {});
  const working =
    live?.games?.working ?? games.filter(([, g]) => (g.status || "working").toLowerCase() === "working").length;
  const total = live?.games?.total ?? games.length;
  const relayKind = resolveRelayStatus(online);
  const syncKind = resolveSyncStatus(live?.sync);

  return (
    <div className="space-y-6">
      {/* Hero */}
      <section className="panel relative overflow-hidden p-6 md:p-10">
        <div className="pointer-events-none absolute -right-24 -top-24 h-64 w-64 rounded-full bg-accent/10 blur-3xl" />
        <div className="relative z-[1] max-w-3xl">
          <div className="mb-4 flex flex-wrap items-center gap-2">
            <StatusPill kind={relayKind} />
            <StatusPill kind={syncKind} size="sm" />
            <FreshnessChip dataUpdatedAt={dataUpdatedAt} live />
          </div>
          <p className="obs-kicker">Alleral Hub</p>
          <h2 className="obs-title mt-2 hero-gradient-text">{site.brand || "Alleral"}</h2>
          <p className="mt-4 text-base leading-relaxed text-muted md:text-lg">{site.tagline}</p>
          {site.announcement ? (
            <div className="mt-5 rounded-xl border border-accent/25 bg-accent/8 px-4 py-3 text-sm text-accent-bright">
              {site.announcement}
            </div>
          ) : null}
          <div className="mt-8 flex flex-wrap gap-2">
            <Button variant="primary" onClick={onCopy}>
              <Copy className="h-4 w-4" /> Copy loader
            </Button>
            <Button onClick={() => setView("games")}>
              <Gamepad2 className="h-4 w-4" /> Browse games
            </Button>
            <Button variant="ghost" onClick={() => setView("status")}>
              <Radio className="h-4 w-4" /> Live status
            </Button>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <MetricCard label="Scripts online" numeric={working} suffix={` / ${total}`} accent="green" trend="Live fleet health" />
        <MetricCard label="Loader" value={`v${live?.versions?.loader || site.loaderVersion || "—"}`} accent="cyan" />
        <MetricCard label="Core" value={`v${live?.versions?.core || site.coreVersion || "—"}`} accent="violet" trend={`Syde patch ${site.sydePatch ?? "—"}`} />
        <MetricCard label="UI" value={site.uiLibrary || "Syde"} accent="yellow" trend={site.uiVersion} />
      </section>

      {/* Features + loader */}
      <section className="grid gap-4 lg:grid-cols-2">
        <div className="panel p-5 md:p-6">
          <div className="mb-4 flex items-center gap-2">
            <Sparkles className="h-4 w-4 text-accent" />
            <h3 className="obs-title-sm">Why Alleral</h3>
          </div>
          <ul className="space-y-2">
            {(site.features || []).slice(0, 6).map((f) => (
              <li key={f} className="flex items-start gap-2 text-sm text-muted">
                <Check className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
                <span>{f}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="panel p-5 md:p-6">
          <div className="obs-panel-head">
            <div>
              <p className="obs-kicker">Bootstrap</p>
              <h3 className="obs-title-sm">Save once — auto-updates forever</h3>
            </div>
            <Button size="sm" variant="ghost" onClick={onCopy}>
              Copy
            </Button>
          </div>
          <pre className="mt-4 max-h-40 overflow-auto rounded-xl border border-border bg-bg-1 p-4 font-mono text-[11px] leading-relaxed text-muted obs-scroll">
            {site.loadstring}
          </pre>
        </div>
      </section>

      {/* Game preview */}
      <section>
        <div className="mb-3 flex items-center justify-between gap-2">
          <h3 className="obs-title-sm">Supported games</h3>
          <Button variant="ghost" size="sm" onClick={() => setView("games")}>
            View all <ArrowRight className="h-3.5 w-3.5" />
          </Button>
        </div>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {games.slice(0, 6).map(([id, game]) => (
            <button
              key={id}
              type="button"
              onClick={() => setView("games")}
              className="panel panel-hover p-4 text-left"
            >
              <div className="flex items-center justify-between gap-2">
                <p className="font-semibold">{game.name || id}</p>
                <Zap className="h-3.5 w-3.5 text-accent" />
              </div>
              <p className="mt-2 line-clamp-2 text-sm text-muted">{game.description}</p>
            </button>
          ))}
        </div>
      </section>

      {/* FAQ */}
      {(site.faq?.length ?? 0) > 0 ? (
        <section className="panel p-5 md:p-6">
          <h3 className="obs-title-sm mb-4">FAQ</h3>
          <div className="space-y-2">
            {site.faq!.map((item) => (
              <details key={item.q} className="faq-item rounded-xl border border-border bg-bg-1 px-4 py-3">
                <summary className="font-medium text-sm">{item.q}</summary>
                <p className="mt-2 text-sm leading-relaxed text-muted">{item.a}</p>
              </details>
            ))}
          </div>
        </section>
      ) : null}

      {/* Resources */}
      {(site.resources?.length ?? 0) > 0 ? (
        <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {site.resources!.map((r) => {
            const href = resolveResourceUrl(site, r);
            if (!href) return null;
            return (
              <a
                key={r.title}
                href={href}
                target={href.startsWith("http") ? "_blank" : undefined}
                rel={href.startsWith("http") ? "noopener noreferrer" : undefined}
                className="panel panel-hover flex items-start gap-3 p-4"
              >
                <ExternalLink className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
                <div>
                  <p className="font-medium text-sm">{r.title}</p>
                  <p className="mt-1 text-xs text-muted">{r.desc}</p>
                </div>
              </a>
            );
          })}
        </section>
      ) : null}
    </div>
  );
}
