"use client";

import { useEffect, useRef, useState } from "react";

export function useMetricHistory<T extends Record<string, number>>(
  snapshot: T | null | undefined,
  maxPoints = 48,
  intervalMs = 15000
) {
  const [history, setHistory] = useState<T[]>([]);
  const lastAt = useRef(0);

  useEffect(() => {
    if (!snapshot) return;
    const now = Date.now();
    if (now - lastAt.current < intervalMs - 500) return;
    lastAt.current = now;
    setHistory((prev) => [...prev.slice(-(maxPoints - 1)), snapshot]);
  }, [snapshot, maxPoints, intervalMs]);

  return history;
}

export function historyToSeries(history: Record<string, number>[], key: string): number[] {
  return history.map((h) => h[key] ?? 0);
}
