"use client";

import clsx from "clsx";
import type { ReactNode } from "react";

type Variant = "primary" | "secondary" | "ghost" | "danger";

const variants: Record<Variant, string> = {
  primary:
    "bg-accent text-bg-0 border border-accent-bright/40 shadow-[0_0_24px_rgba(83,252,18,0.28)] hover:brightness-110",
  secondary: "panel text-text hover:border-border-strong",
  ghost: "border border-transparent text-muted hover:text-text hover:bg-white/[0.04]",
  danger: "border border-red-400/30 bg-red-400/10 text-red-300",
};

type ButtonProps = {
  children: ReactNode;
  className?: string;
  variant?: Variant;
  size?: "sm" | "md" | "lg";
  type?: "button" | "submit" | "reset";
  disabled?: boolean;
  onClick?: () => void;
};

export function Button({
  children,
  className,
  variant = "secondary",
  size = "md",
  type = "button",
  disabled,
  onClick,
}: ButtonProps) {
  const sizes = {
    sm: "px-3 py-1.5 text-xs rounded-lg",
    md: "px-4 py-2 text-sm rounded-xl",
    lg: "px-5 py-2.5 text-sm rounded-xl",
  };

  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      className={clsx(
        "inline-flex items-center justify-center gap-2 font-medium transition-[transform,filter,background] duration-150 active:scale-[0.98] disabled:opacity-50",
        variants[variant],
        sizes[size],
        className
      )}
    >
      {children}
    </button>
  );
}

export function Kbd({ children }: { children: ReactNode }) {
  return (
    <kbd className="rounded-md border border-border bg-bg-2 px-1.5 py-0.5 font-mono text-[10px] text-muted">{children}</kbd>
  );
}
