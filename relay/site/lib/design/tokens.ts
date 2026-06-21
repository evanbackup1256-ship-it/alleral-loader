export const status = {
  healthy: { label: "Healthy", color: "#34d399", glow: "rgba(52,211,153,0.45)" },
  online: { label: "Online", color: "#06b6d4", glow: "rgba(6,182,212,0.4)" },
  syncing: { label: "Syncing", color: "#8b5cf6", glow: "rgba(139,92,246,0.45)" },
  idle: { label: "Idle", color: "#94a3b8", glow: "rgba(148,163,184,0.25)" },
  warning: { label: "Warning", color: "#fbbf24", glow: "rgba(251,191,36,0.4)" },
  error: { label: "Error", color: "#f87171", glow: "rgba(248,113,113,0.45)" },
  offline: { label: "Offline", color: "#64748b", glow: "rgba(100,116,139,0.3)" },
} as const;

export type StatusKind = keyof typeof status;

export const chart = {
  grid: "rgba(255,255,255,0.04)",
  axis: "rgba(148,163,184,0.5)",
  linePrimary: "#8b5cf6",
  lineSecondary: "#06b6d4",
  areaPrimary: "rgba(139,92,246,0.12)",
  crosshair: "rgba(255,255,255,0.25)",
  pointGlow: "rgba(6,182,212,0.6)",
} as const;

export const brand = {
  violet: "#8b5cf6",
  cyan: "#06b6d4",
  void: "#020308",
  card: "#0c121c",
} as const;