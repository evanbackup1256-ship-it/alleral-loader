"use client";

export function ChartTooltip({
  x,
  y,
  label,
  value,
  visible,
}: {
  x: number;
  y: number;
  label?: string;
  value?: string | number;
  visible?: boolean;
}) {
  if (!visible) return null;
  return (
    <div
      className="chart-tooltip pointer-events-none absolute z-10 font-mono text-[10px]"
      style={{ left: x, top: y, transform: "translate(-50%, -120%)" }}
    >
      {label ? <p className="text-muted-2">{label}</p> : null}
      <p className="font-semibold text-text">{value}</p>
    </div>
  );
}
