import type { Metadata, Viewport } from "next";
import { IBM_Plex_Mono, Outfit } from "next/font/google";
import { Toaster } from "sonner";
import "./globals.css";
import { cn } from "@/lib/utils";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
});

const mono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Alleral — Script Hub",
  description:
    "Roblox scripts that stay updated. One loadstring, live game routing, WindUI runtime, and executor intel from WEAO.",
  openGraph: {
    title: "Alleral — Script Hub",
    description: "One loader. Live pins. Premium WindUI.",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#020308",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={cn(outfit.variable, mono.variable)}>
      <body className="site-body antialiased">
        {children}
        <Toaster
          theme="dark"
          position="bottom-right"
          visibleToasts={3}
          gap={10}
          toastOptions={{
            unstyled: true,
            classNames: {
              toast: "toast-panel",
            },
          }}
        />
      </body>
    </html>
  );
}