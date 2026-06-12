"use client";

import { useEffect, useState } from "react";
import { useSpring } from "motion/react";
import { spring } from "@/lib/motion/config";

export function AnimatedNumber({ value, className }: { value: number; className?: string }) {
  const motionValue = useSpring(value, spring.soft);
  const [display, setDisplay] = useState(value);

  useEffect(() => {
    motionValue.set(value);
    const unsub = motionValue.on("change", (v) => setDisplay(Math.round(v)));
    return () => unsub();
  }, [value, motionValue]);

  return <span className={className}>{display.toLocaleString()}</span>;
}
