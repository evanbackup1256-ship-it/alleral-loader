"use client";

import { useCallback, useEffect, useState } from "react";
import { fetchLiveStatus } from "@/lib/api";
import type { HubStatusPayload } from "@/lib/types";

export function useHubStatus(intervalMs = 15000) {
  const [data, setData] = useState<HubStatusPayload | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updatedAt, setUpdatedAt] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      const next = await fetchLiveStatus();
      setData(next);
      setError(null);
      setUpdatedAt(Date.now());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not reach relay");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
    const t = setInterval(refresh, intervalMs);
    return () => clearInterval(t);
  }, [refresh, intervalMs]);

  const secondsAgo = updatedAt ? Math.max(0, Math.floor((Date.now() - updatedAt) / 1000)) : null;

  return { data, error, loading, refresh, updatedAt, secondsAgo };
}
