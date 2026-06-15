"use client";

import clsx from "clsx";
import * as Popover from "@radix-ui/react-popover";
import { Check, ChevronDown } from "lucide-react";
import { memo, useEffect, useId, useMemo, useState } from "react";

export type SelectOption = { value: string; label: string };

function normalizeOptions(options: SelectOption[] | string[]): SelectOption[] {
  return options.map((o) => (typeof o === "string" ? { value: o, label: o } : o));
}

export const Select = memo(function Select({
  name,
  options,
  value,
  defaultValue,
  onChange,
  required,
  placeholder = "Select…",
  className,
  disabled,
}: {
  name: string;
  options: SelectOption[] | string[];
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  required?: boolean;
  placeholder?: string;
  className?: string;
  disabled?: boolean;
}) {
  const items = useMemo(() => normalizeOptions(options), [options]);
  const listId = useId();
  const [open, setOpen] = useState(false);
  const [internal, setInternal] = useState(defaultValue ?? items[0]?.value ?? "");
  const current = value ?? internal;
  const selected = items.find((o) => o.value === current);
  const label = selected?.label ?? placeholder;

  useEffect(() => {
    if (defaultValue !== undefined) setInternal(defaultValue);
  }, [defaultValue]);

  const pick = (next: string) => {
    setInternal(next);
    onChange?.(next);
    setOpen(false);
  };

  return (
    <Popover.Root open={open} onOpenChange={setOpen}>
      <input type="hidden" name={name} value={current} required={required && !current} readOnly />
      <Popover.Trigger asChild disabled={disabled}>
        <button
          type="button"
          className={clsx(
            "flex w-full items-center justify-between gap-2 rounded-xl border border-border bg-bg-1 px-3.5 py-2.5 text-left text-sm outline-none transition",
            "hover:border-border-strong hover:bg-bg-2",
            "focus:border-accent/50 focus:shadow-[0_0_0_3px_rgba(83,252,18,0.15)]",
            open && "border-accent/50 shadow-[0_0_0_3px_rgba(83,252,18,0.15)]",
            disabled && "cursor-not-allowed opacity-50",
            className
          )}
          aria-expanded={open}
          aria-haspopup="listbox"
          aria-controls={listId}
        >
          <span className={clsx("truncate", !selected && "text-muted")}>{label}</span>
          <ChevronDown className={clsx("h-4 w-4 shrink-0 text-muted transition-transform duration-200", open && "rotate-180")} />
        </button>
      </Popover.Trigger>
      <Popover.Portal>
        <Popover.Content
          id={listId}
          role="listbox"
          sideOffset={8}
          align="start"
          collisionPadding={12}
          onOpenAutoFocus={(e) => e.preventDefault()}
          className="z-[600] view-enter flex max-h-60 w-[var(--radix-popover-trigger-width)] flex-col gap-0.5 overflow-y-auto overscroll-contain rounded-xl border border-border-strong bg-bg-3 p-1.5 shadow-[0_24px_60px_rgba(0,0,0,0.55)]"
        >
          {items.map((opt) => {
            const active = opt.value === current;
            return (
              <button
                key={`${opt.value}-${opt.label}`}
                type="button"
                role="option"
                aria-selected={active}
                className={clsx(
                  "flex w-full items-center justify-between gap-2 rounded-lg px-3 py-2 text-left text-sm transition",
                  active
                    ? "bg-accent/15 text-text"
                    : "text-muted hover:bg-white/[0.06] hover:text-text"
                )}
                onClick={() => pick(opt.value)}
              >
                <span className="truncate">{opt.label}</span>
                {active ? <Check className="h-3.5 w-3.5 shrink-0 text-accent-bright" /> : null}
              </button>
            );
          })}
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  );
});

export function Input({ className, ...props }: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={clsx(
        "w-full rounded-xl border border-border bg-bg-1 px-3.5 py-2.5 text-sm outline-none transition",
        "hover:border-border-strong focus:border-accent/50 focus:shadow-[0_0_0_3px_rgba(83,252,18,0.15)]",
        className
      )}
      {...props}
    />
  );
}

export function Textarea({ className, ...props }: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className={clsx(
        "min-h-[100px] w-full rounded-xl border border-border bg-bg-1 px-3.5 py-2.5 text-sm outline-none transition",
        "hover:border-border-strong focus:border-accent/50 focus:shadow-[0_0_0_3px_rgba(83,252,18,0.15)]",
        className
      )}
      {...props}
    />
  );
}

export function Badge({
  children,
  tone = "neutral",
  className,
}: {
  children: React.ReactNode;
  tone?: "neutral" | "green" | "cyan" | "violet" | "red" | "yellow";
  className?: string;
}) {
  const tones = {
    neutral: "border-border text-muted bg-white/[0.03]",
    green: "border-green-400/25 text-green-300 bg-green-400/10",
    cyan: "border-cyan-400/25 text-cyan-300 bg-cyan-400/10",
    violet: "border-violet-400/25 text-violet-300 bg-violet-400/10",
    red: "border-red-400/25 text-red-300 bg-red-400/10",
    yellow: "border-yellow-400/25 text-yellow-300 bg-yellow-400/10",
  };
  return (
    <span className={clsx("inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[0.68rem] font-medium", tones[tone], className)}>
      {children}
    </span>
  );
}
