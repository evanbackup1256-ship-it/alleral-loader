"use client";

import { useMemo } from "react";
import { Group, Panel, Separator } from "react-resizable-panels";
import { Activity, Gamepad2, Layers, Radio } from "lucide-react";
import { useHubStatus } from "@/lib/hooks/useHubStatus";
import { useMetricHistory, historyToSeries } from "@/lib/hooks/useMetricHistory";
import { resolveRelayStatus } from "@/lib/status/resolve";
import type { SitePayload } from "@/lib/types";
import { MetricCard } from "@/components/observability/MetricCard";
import { SyncMonitor } from "@/components/observability/SyncMonitor";
import { HealthRing } from "@/components/observability/HealthRing";
import { FreshnessChip } from "@/components/observability/FreshnessChip";
import { StatusPill } from "@/components/observability/StatusPill";
import { TelemetryLineChart } from "@/components/charts/TelemetryLineChart";
import { StatusHeatmap } from "@/components/charts/StatusHeatmap";
import { EventTimeline, GameStatusStream } from "@/components/charts/EventTimeline";
import { ServiceGraph } from "@/components/charts/ServiceGraph";

export function CommandCenter({ site }: { site: SitePayload }) {
  const { data, error, secondsAgo, loading } = useHubStatus(12000);
  const online = !error && data?.ok !== false;
  const relayKind = resolveRelayStatus(online, error);

  const games =
    data?.games?.items?.length ?
      data.games.items
    : Object.entries(site.games || {}).map(([id, g]) => ({
        id,
        name: g.name || id,
        status: (g.status || "working").toLowerCase(),
        version: g.version,
        message: g.message,
      }));

  const working = data?.games?.working ?? games.filter((g) => (g.status || "working") === "working").length;
  const total = data?.games?.total ?? games.length;
  const healthPct = total ? Math.round((working / total) * 100) : 100;

  const snapshot = useMemo(
    () => ({ working, total, health: healthPct }),
    [working, total, healthPct]
  );
  const history = useMetricHistory(snapshot, 36, 12000);
  const workingSeries = historyToSeries(history, "working").map((v, i) => ({
    value: v,
    label: `T${i}`,
  }));
  const healthSeries = historyToSeries(history, "health").map((v, i) => ({
    value: v,
    label: `T${i}`,
  }));

  const timeline = useMemo(() => {
    const items: { at?: string; title?: string; detail?: string; kind?: "release" | "sync" | "status" }[] = [];
    if (data?.sync?.lastSyncAt) {
      items.push({ at: new Date(data.sync.lastSyncAt).toLocaleTimeString(), title: "GitHub sync completed", kind: "sync", detail: "Scripts refreshed from repository" });
    }
    (data?.changelog || []).slice(0, 5).forEach((c) => {
      items.push({ at: c.date, title: c.title, detail: c.items?.[0], kind: "release" });
    });
    if (site.announcement) {
      items.push({ at: "Now", title: "Announcement", detail: site.announcement, kind: "status" });
    }
    return items;
  }, [data, site.announcement]);

  const chartData =
    workingSeries.length > 2 ?
      workingSeries
    : Array.from({ length: 24 }, (_, i) => ({
        value: working + Math.sin(i * 0.5) * 0.6 + (i % 3) * 0.2,
        label: `${i}h`,
      }));

  return (
    <div className="command-center h-[min(82vh,960px)] min-h-[640px]">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="obs-kicker">Observability</p>
          <h2 className="obs-title">Mission control</h2>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <StatusPill kind={relayKind} pulse={online} />
          <FreshnessChip secondsAgo={secondsAgo} live={!loading} />
        </div>
      </div>

      <Group orientation="horizontal" className="h-[calc(100%-3.5rem)] gap-2">
        <Panel defaultSize={20} minSize={16} maxSize={28}>
          <div className="flex h-full flex-col gap-3 pr-1">
            <div className="obs-panel flex items-center gap-4">
              <HealthRing kind={healthPct >= 80 ? "healthy" : healthPct >= 50 ? "warning" : "error"} value={healthPct} label="Health" />
              <div>
                <p className="obs-kicker">Fleet health</p>
                <p className="text-sm text-muted">{working} of {total} scripts operational</p>
              </div>
            </div>
            <MetricCard label="Working scripts" numeric={working} icon={Gamepad2} accent="green" sparkline={historyToSeries(history, "working")} trend="Live from relay" />
            <MetricCard label="Tracked games" numeric={total} icon={Layers} accent="violet" />
            <SyncMonitor sync={data?.sync} secondsAgo={secondsAgo} online={online} />
          </div>
        </Panel>

        <Separator className="obs-separator" />

        <Panel defaultSize={52} minSize={36}>
          <Group orientation="vertical" className="h-full gap-2">
            <Panel defaultSize={58} minSize={35}>
              <div className="obs-panel obs-panel-chart h-full">
                <div className="obs-panel-head">
                  <div>
                    <p className="obs-kicker">Throughput</p>
                    <h3 className="obs-title-sm">Working scripts · rolling window</h3>
                  </div>
                  <Activity className="h-4 w-4 text-cyan-400" strokeWidth={1.75} />
                </div>
                <TelemetryLineChart series={chartData} secondary={healthSeries.length > 2 ? healthSeries : undefined} className="mt-2 h-[calc(100%-3rem)] min-h-[200px]" />
              </div>
            </Panel>
            <Separator className="obs-separator horizontal" />
            <Panel defaultSize={42} minSize={28}>
              <div className="grid h-full gap-2 md:grid-cols-2">
                <StatusHeatmap games={games} className="h-full" />
                <ServiceGraph games={games.slice(0, 8)} className="h-full" />
              </div>
            </Panel>
          </Group>
        </Panel>

        <Separator className="obs-separator" />

        <Panel defaultSize={28} minSize={20} maxSize={36}>
          <Group orientation="vertical" className="h-full gap-2 pl-1">
            <Panel defaultSize={55} minSize={30}>
              <GameStatusStream games={games} className="h-full" />
            </Panel>
            <Separator className="obs-separator horizontal" />
            <Panel defaultSize={45} minSize={25}>
              <EventTimeline events={timeline} className="h-full" />
            </Panel>
          </Group>
        </Panel>
      </Group>

      <div className="mt-3 flex flex-wrap gap-2 font-mono text-[10px] text-muted-2">
        <span className="inline-flex items-center gap-1"><Radio className="h-3 w-3" /> loader {data?.versions?.loader || site.loaderVersion || "—"}</span>
        <span>core {data?.versions?.core || site.coreVersion || "—"}</span>
        <span>{data?.versions?.ui || site.uiLibrary} {data?.versions?.uiVersion || site.uiVersion}</span>
      </div>
    </div>
  );
}
