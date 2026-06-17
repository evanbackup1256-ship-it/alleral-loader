"use client";

import { useState } from "react";
import * as RadixSelect from "@radix-ui/react-select";
import { ChevronDown, Check } from "lucide-react";

const issueTypes = [
  "Loader Issue", "Script Failure", "Runtime Issue", "Game Update Breakage",
  "Access Problem", "Bug Report", "Feature Request", "Other",
] as const;

export function SupportSelect({ value, onChange, label }: { value: string; onChange: (v: string) => void; label: string }) {
  return (
    <div>
      <label className="block text-xs font-mono text-muted-2 uppercase tracking-wider mb-1.5">{label}</label>
      <RadixSelect.Root value={value} onValueChange={onChange}>
        <RadixSelect.Trigger className="w-full rounded-lg border border-white/10 bg-bg-0/80 px-4 py-2.5 text-sm text-text outline-none transition focus:border-accent/40 focus:ring-1 focus:ring-accent/20 flex items-center justify-between gap-2">
          <RadixSelect.Value />
          <RadixSelect.Icon><ChevronDown className="h-4 w-4 text-muted-2" /></RadixSelect.Icon>
        </RadixSelect.Trigger>
        <RadixSelect.Portal>
          <RadixSelect.Content className="rounded-lg border border-white/10 bg-bg-1/95 backdrop-blur-2xl shadow-2xl p-1 z-[300]" position="popper" sideOffset={4}>
            <RadixSelect.Viewport>
              {issueTypes.map((t) => (
                <RadixSelect.Item key={t} value={t} className="flex items-center gap-2 rounded-md px-3 py-2 text-sm text-text cursor-pointer outline-none hover:bg-accent/10 hover:text-accent-bright data-[highlighted]:bg-accent/10 data-[highlighted]:text-accent-bright data-[state=checked]:text-accent-bright">
                  <RadixSelect.ItemText>{t}</RadixSelect.ItemText>
                  <RadixSelect.ItemIndicator className="ml-auto"><Check className="h-3.5 w-3.5 text-accent" /></RadixSelect.ItemIndicator>
                </RadixSelect.Item>
              ))}
            </RadixSelect.Viewport>
          </RadixSelect.Content>
        </RadixSelect.Portal>
      </RadixSelect.Root>
    </div>
  );
}
