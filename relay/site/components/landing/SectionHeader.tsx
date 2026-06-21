import type { LucideIcon } from "lucide-react";

export function SectionHeader({
  kicker,
  icon: Icon,
  title,
  description,
  align = "center",
}: {
  kicker: string;
  icon?: LucideIcon;
  title: string;
  description?: string;
  align?: "center" | "left";
}) {
  return (
    <div className={align === "center" ? "section-intro" : "max-w-2xl"}>
      <div className="kicker">
        {Icon ? <Icon className="h-3.5 w-3.5" /> : null}
        {kicker}
      </div>
      <h2 className="display-lg mt-5">{title}</h2>
      {description ? <p>{description}</p> : null}
    </div>
  );
}