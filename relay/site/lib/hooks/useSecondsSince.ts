"use client";

import { useEffect, useState } from "react";

export function useSecondsSince(timestamp: number | null | undefined, intervalMs = 1000) {
  const [seconds, setSeconds] = useState<number | null>(() =>
    timestamp ? Math.max(0, Math.floor((Date.now() - timestamp) / 1000)) : null
  );

  useEffect(() => {
    if (!timestamp) {
      setSeconds(null);
      return;
    }
    const tick = () => setSeconds(Math.max(0, Math.floor((Date.now() - timestamp) / 1000)));
    tick();
    const id = window.setInterval(tick, intervalMs);
    return () => window.clearInterval(id);
  }, [timestamp, intervalMs]);

  return seconds;
}
