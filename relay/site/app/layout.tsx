import type { Metadata, Viewport } from "next";
import { Outfit, IBM_Plex_Mono } from "next/font/google";
import { Toaster } from "sonner";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
  display: "swap",
  preload: true,
});

const plexMono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500"],
  variable: "--font-mono",
  display: "swap",
  preload: false,
});

export const metadata: Metadata = {
  title: "Alleral Hub",
  description: "Roblox scripts that stay updated — live game status, loader, and executor compatibility.",
};

export const viewport: Viewport = {
  themeColor: "#030508",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${outfit.variable} ${plexMono.variable}`}>
      <body className="site-body hub-shell">
        {children}
        <Toaster
          theme="dark"
          position="bottom-right"
          visibleToasts={3}
          gap={8}
          toastOptions={{
            unstyled: true,
            classNames: {
              toast: "panel-raised px-4 py-3 text-sm",
            },
          }}
        />
      </body>
    </html>
  );
}
