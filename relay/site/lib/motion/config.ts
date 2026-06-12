export const spring = {
  snappy: { type: "spring" as const, stiffness: 480, damping: 34, mass: 0.72 },
  soft: { type: "spring" as const, stiffness: 280, damping: 30, mass: 0.95 },
  panel: { type: "spring" as const, stiffness: 340, damping: 36, mass: 0.88 },
  magnetic: { type: "spring" as const, stiffness: 200, damping: 20, mass: 0.55 },
  layout: { type: "spring" as const, stiffness: 380, damping: 38, mass: 0.9 },
  tooltip: { type: "spring" as const, stiffness: 520, damping: 38, mass: 0.65 },
  status: { type: "spring" as const, stiffness: 420, damping: 32, mass: 0.7 },
};

export const stagger = {
  fast: 0.035,
  base: 0.055,
  slow: 0.085,
  children: 0.04,
};

export const reveal = {
  initial: { opacity: 0, y: 16 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -10 },
};
