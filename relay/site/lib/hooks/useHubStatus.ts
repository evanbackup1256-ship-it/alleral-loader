"use client";

import { useLiveSyncMeta } from "@/lib/queries/hooks";

/** @deprecated Use useLiveSyncMeta from lib/queries/hooks */
export function useHubStatus() {
  return useLiveSyncMeta();
}

export { HubStatusProvider } from "@/components/providers/HubStatusProvider";
