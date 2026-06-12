import type { StatusKind } from "@/lib/design/tokens";

export function resolveRelayStatus(online?: boolean, error?: string | null): StatusKind {
  if (error) return "error";
  if (online === false) return "offline";
  return "online";
}

export function resolveSyncStatus(sync?: {
  enabled?: boolean;
  autoStatus?: boolean;
  lastError?: string | null;
}): StatusKind {
  if (sync?.lastError) return "error";
  if (sync?.autoStatus) return "syncing";
  if (sync?.enabled) return "healthy";
  return "idle";
}

export function resolveGameStatus(status?: string): StatusKind {
  const s = (status || "working").toLowerCase();
  if (s === "working") return "healthy";
  if (s === "testing") return "syncing";
  if (s === "maintenance") return "warning";
  if (s === "broken") return "error";
  return "idle";
}

export function formatFreshness(seconds: number | null | undefined): string {
  if (seconds == null) return "Awaiting data";
  if (seconds < 5) return "Just now";
  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  return `${Math.floor(seconds / 3600)}h ago`;
}

export function formatDisplayValue(value: unknown, fallback = "—"): string {
  if (value == null || value === "") return fallback;
  if (typeof value === "boolean") return value ? "Active" : "Inactive";
  if (value === "true" || value === "false") return value === "true" ? "Active" : "Inactive";
  return String(value);
}
