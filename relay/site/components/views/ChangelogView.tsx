"use client";

import type { SitePayload } from "@/lib/types";
import { Panel } from "@/components/ui/Panel";

export function ChangelogView({ site }: { site: SitePayload }) {
  const entries = site.changelog || [];

  return (
    <div className="mx-auto max-w-3xl space-y-3">
      {entries.map((entry) => (
        <Panel key={`${entry.date}-${entry.title}`} padding="md" hover>
          <h3 className="font-semibold">{entry.title}</h3>
          <p className="mb-3 text-xs text-muted-2">{entry.date}</p>
          <ul className="list-disc space-y-1 pl-5 text-sm text-muted">
            {(entry.items || []).map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </Panel>
      ))}
    </div>
  );
}
