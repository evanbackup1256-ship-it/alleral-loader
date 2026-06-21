"use client";

import { LogIn, Shield } from "lucide-react";

export function AdminModal({
  open,
  password,
  onPassword,
  onClose,
  onSubmit,
}: {
  open: boolean;
  password: string;
  onPassword: (v: string) => void;
  onClose: () => void;
  onSubmit: () => void;
}) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[200] grid place-items-center p-4">
      <button type="button" className="absolute inset-0 bg-black/70" onClick={onClose} aria-label="Close" />
      <div className="surface-card relative z-10 w-full max-w-sm p-6" onClick={(e) => e.stopPropagation()}>
        <div className="mb-5 flex items-center gap-3">
          <Shield className="h-5 w-5 text-violet-bright" />
          <h3 className="text-lg font-semibold">Admin access</h3>
        </div>
        <input
          type="password"
          value={password}
          onChange={(e) => onPassword(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") onSubmit();
          }}
          placeholder="Enter admin password"
          className="input-field"
          autoFocus
        />
        <div className="mt-4 flex gap-2">
          <button type="button" className="btn btn-primary flex-1" onClick={onSubmit}>
            <LogIn className="h-4 w-4" />
            Sign in
          </button>
          <button type="button" className="btn btn-ghost flex-1" onClick={onClose}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}