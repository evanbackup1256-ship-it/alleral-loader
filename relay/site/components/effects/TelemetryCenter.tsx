"use client";

import { useState, useEffect } from "react";
import { Activity, Radio, Cpu, Zap, Globe, Server } from "lucide-react";
import { StatusDot } from "./StatusDot";
import { LiveEventStream } from "./LiveEventStream";

function useRandomPoints(count = 20) {
  const [points, setPoints] = useState<number[]>(() => Array.from({ length: count }, () => Math.random() * 40 + 10));
  useEffect(() => {
    const interval = setInterval(() => {
      setPoints((prev) => [...prev.slice(1), Math.random() * 40 + 10]);
    }, 800);
    return () => clearInterval(interval);
  }, []);
  return points;
}

function MiniChart({ color = "#00f0c8" }: { color?: string }) {
  const pts = useRandomPoints(20);
  const w = 120;
  const h = 32;
  const max = 50;
  const path = pts.map((p, i) => `${i === 0 ? "M" : "L"}${(i / pts.length) * w},${h - (p / max) * h}`).join(" ");
  const area = `${path} L${w},${h} L0,${h} Z`;

  return (
    <svg width={w} height={h} className="w-full h-8">
      <defs>
        <linearGradient id={`grad-${color}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.25" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill={`url(#grad-${color})`} />
      <path d={path} fill="none" stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

const telemetryMetrics = [
  { label: "Runtime Latency", value: "24ms", status: "working", color: "#00f0c8", icon: Radio },
  { label: "Signal Throughput", value: "1.2k/s", status: "working", color: "#00d4ff", icon: Activity },
  { label: "Active Nodes", value: "12", status: "working", color: "#7c3aed", icon: Cpu },
  { label: "Request Volume", value: "4.8k", status: "working", color: "#00f0c8", icon: Zap },
  { label: "Edge Latency", value: "8ms", status: "working", color: "#00d4ff", icon: Globe },
  { label: "Cache Hit Rate", value: "87%", status: "stable", color: "#7c3aed", icon: Server },
];

export function TelemetryCenter() {
  return (
    <section id="telemetry" className="relative py-24 md:py-32">
      <div className="mx-auto max-w-7xl px-4 md:px-6">
        <div className="section-head">
          <div className="kicker"><Radio className="h-3 w-3" /> Telemetry Center</div>
          <h2 className="heading-lg mt-4">Real-time runtime observability.</h2>
          <p>Latency, throughput, node health, and signal metrics from the global relay.</p>
        </div>

        <div className="mt-14 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {telemetryMetrics.map((m) => (
            <div key={m.label} className="glass-premium rounded-xl p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <m.icon className="h-4 w-4" style={{ color: m.color }} />
                  <span className="text-xs font-mono text-muted-2 uppercase tracking-wider">{m.label}</span>
                </div>
                <StatusDot status={m.status} />
              </div>
              <div className="flex items-end justify-between mb-2">
                <span className="text-2xl font-bold text-text">{m.value}</span>
                <span className="text-[10px] font-mono text-muted-2">live</span>
              </div>
              <MiniChart color={m.color} />
            </div>
          ))}
        </div>

        <div className="mt-8 max-w-md mx-auto">
          <LiveEventStream />
        </div>
      </div>
    </section>
  );
}
