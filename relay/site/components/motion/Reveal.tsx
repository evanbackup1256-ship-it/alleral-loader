"use client";

import clsx from "clsx";
import type { ReactNode } from "react";

export function Reveal({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={clsx("view-enter", className)}>{children}</div>;
}

export function Stagger({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={className}>{children}</div>;
}

export function StaggerItem({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={clsx("view-enter", className)}>{children}</div>;
}

export function PageTransition({ children }: { children: ReactNode }) {
  return <div className="view-enter">{children}</div>;
}

export function InViewReveal({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={clsx("view-enter", className)}>{children}</div>;
}
