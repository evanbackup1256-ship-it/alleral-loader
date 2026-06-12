"use client";

import type { ReactNode } from "react";

/** Legacy wrapper — live data is powered by React Query in QueryProvider. */
export function HubStatusProvider({ children }: { children: ReactNode }) {
  return children;
}
