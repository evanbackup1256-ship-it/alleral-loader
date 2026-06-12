"use client";

import { QueryClientProvider } from "@tanstack/react-query";
import { useEffect, type ReactNode } from "react";
import { getQueryClient } from "@/lib/query-client";
import { liveStatusQueryKey } from "@/lib/queries/hooks";

export function QueryProvider({ children }: { children: ReactNode }) {
  const client = getQueryClient();

  useEffect(() => {
    const onVisible = () => {
      if (document.visibilityState === "visible") {
        void client.invalidateQueries({ queryKey: liveStatusQueryKey });
      }
    };
    document.addEventListener("visibilitychange", onVisible);
    return () => document.removeEventListener("visibilitychange", onVisible);
  }, [client]);

  return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
}
