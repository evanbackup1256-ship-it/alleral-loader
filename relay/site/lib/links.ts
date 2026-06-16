import { API_BASE, PUBLIC_URL } from "./config";
import type { SitePayload } from "./types";

export function resolveAdminUrl(site?: SitePayload | null): string {
  if (site?.links?.admin) return site.links.admin;
  const relay = site?.links?.relay?.replace(/\/+$/, "");
  if (relay) return `${relay}/admin`;
  if (API_BASE) return `${API_BASE.replace(/\/+$/, "")}/admin`;
  if (typeof window !== "undefined" && !window.location.hostname.includes("github.io")) {
    return `${window.location.origin.replace(/\/+$/, "")}/admin`;
  }
  return `${PUBLIC_URL.replace(/\/+$/, "")}/admin`;
}

export function openExternalUrl(url: string, sameTab = false) {
  if (typeof window === "undefined") return;
  try {
    const target = new URL(url, window.location.href);
    if (sameTab || target.origin === window.location.origin) {
      window.location.assign(target.href);
      return;
    }
  } catch {
    /* fall through */
  }
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.target = "_blank";
  anchor.rel = "noopener noreferrer";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
