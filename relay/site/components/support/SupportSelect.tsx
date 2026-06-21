"use client";

import * as RadixSelect from "@radix-ui/react-select";
import { ChevronDown, Check } from "lucide-react";

const issueTypes = [
  "Loader Issue",
  "Script Failure",
  "Runtime Issue",
  "Game Update Breakage",
  "Access Problem",
  "Bug Report",
  "Feature Request",
  "Other",
] as const;

export function SupportSelect({
  value,
  onChange,
  label,
}: {
  value: string;
  onChange: (v: string) => void;
  label: string;
}) {
  return (
    <div>
      <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">{label}</label>
      <RadixSelect.Root value={value} onValueChange={onChange}>
        <RadixSelect.Trigger className="input-field flex items-center justify-between gap-2">
          <RadixSelect.Value />
          <RadixSelect.Icon>
            <ChevronDown className="h-4 w-4 text-muted-2" />
          </RadixSelect.Icon>
        </RadixSelect.Trigger>
        <RadixSelect.Portal>
          <RadixSelect.Content
            className="z-[300] rounded-xl border border-white/10 bg-card/95 p-1 shadow-2xl backdrop-blur-2xl"
            position="popper"
            sideOffset={4}
          >
            <RadixSelect.Viewport>
              {issueTypes.map((t) => (
                <RadixSelect.Item
                  key={t}
                  value={t}
                  className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm text-text outline-none hover:bg-violet/10 hover:text-violet-bright data-[highlighted]:bg-violet/10 data-[highlighted]:text-violet-bright data-[state=checked]:text-violet-bright"
                >
                  <RadixSelect.ItemText>{t}</RadixSelect.ItemText>
                  <RadixSelect.ItemIndicator className="ml-auto">
                    <Check className="h-3.5 w-3.5 text-violet-bright" />
                  </RadixSelect.ItemIndicator>
                </RadixSelect.Item>
              ))}
            </RadixSelect.Viewport>
          </RadixSelect.Content>
        </RadixSelect.Portal>
      </RadixSelect.Root>
    </div>
  );
}