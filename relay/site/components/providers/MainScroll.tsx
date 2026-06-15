"use client";

import clsx from "clsx";
import type { ReactNode } from "react";

export function MainScroll({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div
      data-scroll-root
      className={clsx("scroll-root flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain", className)}
    >
      {children}
    </div>
  );
}

export function ScrollContent({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={clsx("flex w-full flex-col", className)}>{children}</div>;
}
