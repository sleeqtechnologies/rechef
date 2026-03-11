import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";

const roobert = localFont({
  src: [
    {
      path: "../public/fonts/Roobert-Regular.ttf",
      weight: "400",
      style: "normal",
    },
    {
      path: "../public/fonts/Roobert-Medium.ttf",
      weight: "500",
      style: "normal",
    },
    {
      path: "../public/fonts/Roobert-SemiBold.ttf",
      weight: "600",
      style: "normal",
    },
  ],
  variable: "--font-roobert",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Rechef - Smart Recipe & Pantry Companion",
  description:
    "Rechef helps you stay on top of cooking. Save and organize recipes, track your pantry, and turn ingredients into smart grocery lists. Upgrade to Rechef Pro for more powerful tools.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${roobert.variable} antialiased`}>{children}</body>
    </html>
  );
}
