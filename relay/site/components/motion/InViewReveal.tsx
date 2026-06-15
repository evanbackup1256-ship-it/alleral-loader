"use client";

import clsx from "clsx";
import type { ReactNode } from "react";

export function InViewReveal({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={clsx("view-enter", className)}>{children}</div>;
}
