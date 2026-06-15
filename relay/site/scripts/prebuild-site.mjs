import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const siteDir = join(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = join(siteDir, "../..");
const src = join(repoRoot, "cfg/site.json");
const dest = join(siteDir, "data/site.snapshot.json");

mkdirSync(dirname(dest), { recursive: true });
copyFileSync(src, dest);

const snapshot = JSON.parse(readFileSync(dest, "utf8"));
writeFileSync(
  join(siteDir, "data/site.meta.json"),
  JSON.stringify({ bakedAt: new Date().toISOString(), version: snapshot.version ?? 1 }, null, 2)
);

console.log(`prebuild-site: baked ${src} → ${dest}`);
