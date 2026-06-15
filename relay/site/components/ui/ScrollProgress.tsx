"use client";

import { useEffect, useState } from "react";

export function ScrollProgress() {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const root = document.querySelector("[data-scroll-root]") as HTMLElement | null;
    if (!root) return;

    const onScroll = () => {
      const max = root.scrollHeight - root.clientHeight;
      setProgress(max > 0 ? root.scrollTop / max : 0);
    };

    onScroll();
    root.addEventListener("scroll", onScroll, { passive: true });
    return () => root.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <div
      className="scroll-progress pointer-events-none fixed inset-x-0 top-0 z-[100] h-0.5 origin-left"
      style={{ transform: `scaleX(${progress})` }}
      aria-hidden
    />
  );
}
