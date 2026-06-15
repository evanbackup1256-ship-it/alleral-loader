"use client";

export function AnimatedNumber({ value, className }: { value: number; className?: string }) {
  return <span className={className}>{value.toLocaleString()}</span>;
}
