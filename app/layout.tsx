import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SpotACat — Discover the cats around you",
  description: "Walk, spot, and collect the cats your city has to offer.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
