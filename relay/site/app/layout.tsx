import type { Metadata, Viewport } from "next";
import { Outfit, IBM_Plex_Mono } from "next/font/google";
import { Toaster } from "sonner";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
  display: "swap",
});

const plexMono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Alleral Observability",
  description: "Premium observability platform — live script health, sync monitoring, and fleet analytics.",
};

export const viewport: Viewport = {
  themeColor: "#020204",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${outfit.variable} ${plexMono.variable}`}>
      <body className="site-body">
        {children}
        <Toaster
          theme="dark"
          position="bottom-center"
          toastOptions={{
            className: "glass-float border border-border text-sm",
          }}
        />
      </body>
    </html>
  );
}
