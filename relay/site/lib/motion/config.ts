export const spring = {
  snappy: { type: "spring" as const, stiffness: 960, damping: 68, mass: 0.36 },
  soft: { type: "spring" as const, stiffness: 560, damping: 60, mass: 0.475 },
  panel: { type: "spring" as const, stiffness: 680, damping: 72, mass: 0.44 },
  magnetic: { type: "spring" as const, stiffness: 400, damping: 40, mass: 0.275 },
  layout: { type: "spring" as const, stiffness: 760, damping: 76, mass: 0.45 },
  tooltip: { type: "spring" as const, stiffness: 1040, damping: 76, mass: 0.325 },
  status: { type: "spring" as const, stiffness: 840, damping: 64, mass: 0.35 },
};

export const stagger = {
  fast: 0.0175,
  base: 0.0275,
  slow: 0.0425,
  children: 0.02,
};

export const reveal = {
  initial: { opacity: 0, y: 16 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -10 },
};
