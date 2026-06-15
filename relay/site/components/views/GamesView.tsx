"use client";

import clsx from "clsx";
import { useEffect, useMemo, useState } from "react";
import { fetchThumbnails } from "@/lib/api";
import { useLiveSyncMeta } from "@/lib/queries/hooks";
import type { GameEntry, SitePayload } from "@/lib/types";
import { FreshnessChip } from "@/components/observability/FreshnessChip";
import { StatusPill } from "@/components/observability/StatusPill";
import { resolveGameStatus } from "@/lib/status/resolve";
import { Input } from "@/components/ui/Form";
import { Button } from "@/components/ui/Button";

const STATUSES = ["all", "working", "testing", "maintenance", "broken"] as const;

export function GamesView({ site }: { site: SitePayload }) {
  const [filter, setFilter] = useState<(typeof STATUSES)[number]>("all");
  const [query, setQuery] = useState("");
  const [thumbs, setThumbs] = useState<Record<string, string>>({});
  const [modal, setModal] = useState<{ id: string; game: GameEntry } | null>(null);
  const { data: live, dataUpdatedAt } = useLiveSyncMeta("games");

  const liveStatus = useMemo(() => {
    const map: Record<string, string> = {};
    live?.games?.items?.forEach((g) => {
      if (g.id) map[g.id] = (g.status || "working").toLowerCase();
    });
    return map;
  }, [live?.games?.items]);

  const games = useMemo(
    () =>
      Object.entries(site.games || {}).map(([id, game]) => ({
        id,
        ...game,
        liveStatus: liveStatus[id] || (game.status || "working").toLowerCase(),
      })),
    [site.games, liveStatus]
  );

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return games.filter((g) => {
      const status = g.liveStatus;
      if (filter !== "all" && status !== filter) return false;
      if (!q) return true;
      return (g.name || g.id).toLowerCase().includes(q) || (g.description || "").toLowerCase().includes(q);
    });
  }, [games, filter, query]);

  useEffect(() => {
    const placeIds = [...new Set(games.map((g) => g.placeIds?.[0]).filter(Boolean).map(String))];
    fetchThumbnails(placeIds).then(setThumbs).catch(() => {});
  }, [games]);

  return (
    <div className="space-y-4">
      <div className="panel flex flex-wrap items-center justify-between gap-3 !py-3">
        <FreshnessChip dataUpdatedAt={dataUpdatedAt} live />
        <p className="text-xs text-muted">{filtered.length} games · live status</p>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {STATUSES.map((s) => (
          <Button key={s} size="sm" variant={filter === s ? "primary" : "ghost"} onClick={() => setFilter(s)} className="capitalize">
            {s}
          </Button>
        ))}
      </div>
      <Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search games…" />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {filtered.map((game) => {
          const status = game.liveStatus;
          const placeId = game.placeIds?.[0] ? String(game.placeIds[0]) : null;
          const thumb = placeId ? thumbs[placeId] : null;
          return (
            <div key={game.id} className="panel panel-hover overflow-hidden p-0">
              <button type="button" className="block w-full text-left" onClick={() => setModal({ id: game.id, game })}>
                <div className="relative h-36 overflow-hidden bg-bg-2">
                  {thumb ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={thumb} alt="" className="absolute inset-0 h-full w-full object-cover" loading="lazy" />
                  ) : (
                    <div className="absolute inset-0 bg-gradient-to-br from-accent/15 to-bg-2" />
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-bg-2 to-transparent" />
                </div>
                <div className="p-4">
                  <div className="mb-2 flex items-center gap-2">
                    <h3 className="font-semibold">{game.name || game.id}</h3>
                    <StatusBadge status={status} />
                  </div>
                  <p className="line-clamp-2 text-sm text-muted">{game.description || game.message || "No description."}</p>
                </div>
              </button>
            </div>
          );
        })}
      </div>

      {modal ? (
        <div className="fixed inset-0 z-[120] grid place-items-center p-4">
          <button type="button" aria-label="Close" className="absolute inset-0 bg-black/70" onClick={() => setModal(null)} />
          <div className="panel-raised view-enter relative max-h-[90vh] w-full max-w-md overflow-auto">
            <button type="button" onClick={() => setModal(null)} className="absolute right-3 top-3 z-10 grid h-8 w-8 place-items-center rounded-full bg-bg-1">
              ×
            </button>
            <div className="p-6">
              <h3 className="text-xl font-semibold">{modal.game.name || modal.id}</h3>
              <p className="mt-3 text-sm text-muted">{modal.game.description || modal.game.message}</p>
              {modal.game.robloxUrl ? (
                <a href={modal.game.robloxUrl} target="_blank" rel="noopener noreferrer" className="mt-4 inline-flex">
                  <Button variant="primary">Open on Roblox</Button>
                </a>
              ) : null}
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const kind = resolveGameStatus(status);
  return <StatusPill kind={kind} size="sm" className="capitalize" label={status} />;
}
