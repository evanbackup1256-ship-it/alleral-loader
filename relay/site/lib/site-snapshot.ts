import raw from "@/data/site.snapshot.json";
import { sanitizePublicSite } from "@/lib/sanitize";
import type { SitePayload } from "@/lib/types";

export const SITE_SNAPSHOT = sanitizePublicSite(raw as SitePayload);
