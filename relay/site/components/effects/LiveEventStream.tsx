"use client";

import { useState, useEffect } from "react";
import { Activity, Shield, Zap, CheckCircle, AlertTriangle, Globe } from "lucide-react";

interface Event {
  id: number;
  icon: typeof Activity;
  text: string;
  time: string;
  color: string;
}

const templates: Omit<Event, "id" | "time">[] = [
  { icon: CheckCircle, text: "Node synchronized", color: "#00f0c8" },
  { icon: CheckCircle, text: "Deployment validated", color: "#00f0c8" },
  { icon: Activity, text: "Signal verified", color: "#00d4ff" },
  { icon: Shield, text: "Edge route updated", color: "#7c3aed" },
  { icon: Zap, text: "Runtime stabilized", color: "#00f0c8" },
  { icon: CheckCircle, text: "Challenge completed", color: "#00d4ff" },
  { icon: Globe, text: "Region online", color: "#7c3aed" },
];

export function LiveEventStream() {
  const [events, setEvents] = useState<Event[]>([]);

  useEffect(() => {
    const add = () => {
      const t = templates[Math.floor(Math.random() * templates.length)];
      const now = new Date();
      const time = `${now.getHours().toString().padStart(2, "0")}:${now.getMinutes().toString().padStart(2, "0")}:${now.getSeconds().toString().padStart(2, "0")}`;
      setEvents((prev) => [{ id: Date.now(), ...t, time }, ...prev].slice(0, 20));
    };
    add();
    const interval = setInterval(add, 4000 + Math.random() * 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="glass-premium rounded-xl p-4">
      <div className="flex items-center gap-2 mb-4">
        <Activity className="h-4 w-4 text-accent" />
        <h3 className="text-sm font-semibold text-text">Live Event Stream</h3>
        <span className="ml-auto flex items-center gap-1.5 text-[10px] font-mono text-muted-2">
          <span className="w-1.5 h-1.5 rounded-full bg-accent animate-pulse" />
          {events.length > 0 && `${events[0].time}`}
        </span>
      </div>
      <div className="space-y-1.5 max-h-[280px] overflow-y-auto scroll-thin">
        {events.map((e, i) => (
          <div
            key={e.id}
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-xs font-mono text-muted bg-white/[0.02]"
            style={{
              animation: i === 0 ? "fadeIn 0.3s ease both" : undefined,
            }}
          >
            <e.icon className="h-3 w-3 shrink-0" style={{ color: e.color }} />
            <span className="flex-1">{e.text}</span>
            <span className="text-muted-2">{e.time}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
