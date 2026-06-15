"use client";

import clsx from "clsx";
import type { ReactNode } from "react";

export function InViewReveal({
  children,
  className,
  delay = 0,
}: {
  children: ReactNode;
  className?: string;
  delay?: number;
}) {
  return (
    <div className={clsx("view-enter", className)} style={{ animationDelay: `${delay}s` }}>
      {children}
    </div>
  );
}
