"use client";

import { CommandCenter } from "@/components/dashboard/CommandCenter";
import type { SitePayload } from "@/lib/types";

export function StatusView({ site }: { site: SitePayload }) {
  return <CommandCenter site={site} />;
}
