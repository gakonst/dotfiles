#!/usr/bin/env node

import { spawn, execSync } from "node:child_process";
import puppeteer from "puppeteer-core";

const args = process.argv.slice(2);
const useProfile = args.includes("--profile");
const headful = args.includes("--headful");
const unknown = args.filter(
  (a) => a !== "--profile" && a !== "--headful",
);

if (unknown.length > 0) {
  console.log("Usage: start.ts [--profile] [--headful]");
  console.log("\nOptions:");
  console.log(
    "  --profile  Copy your default Chrome profile (cookies, logins)",
  );
  console.log("  --headful  Launch with a visible window (default is headless)");
  console.log("\nExamples:");
  console.log("  start.ts                   # Headless, fresh profile");
  console.log("  start.ts --profile         # Headless, with your profile");
  console.log("  start.ts --headful         # Visible window, fresh profile");
  console.log("  start.ts --profile --headful # Visible window, your profile");
  process.exit(1);
}

// Kill existing Chrome
try {
  execSync("killall 'Google Chrome'", { stdio: "ignore" });
} catch {}

// Wait a bit for processes to fully die
await new Promise((r) => setTimeout(r, 1000));

// Setup profile directory
execSync("mkdir -p ~/.cache/scraping", { stdio: "ignore" });

if (useProfile) {
  // Sync profile with rsync (much faster on subsequent runs)
  execSync(
    `rsync -a --delete "${process.env["HOME"]}/Library/Application Support/Google/Chrome/" ~/.cache/scraping/`,
    { stdio: "pipe" },
  );
}

// Start Chrome in background (detached so Node can exit)
const chromeArgs = [
  "--remote-debugging-port=9222",
  `--user-data-dir=${process.env["HOME"]}/.cache/scraping`,
];

if (!headful) {
  chromeArgs.push("--headless=new");
}

spawn(
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  chromeArgs,
  { detached: true, stdio: "ignore" },
).unref();

// Wait for Chrome to be ready by attempting to connect
let connected = false;
for (let i = 0; i < 30; i++) {
  try {
    const browser = await puppeteer.connect({
      browserURL: "http://localhost:9222",
      defaultViewport: null,
    });
    await browser.disconnect();
    connected = true;
    break;
  } catch {
    await new Promise((r) => setTimeout(r, 500));
  }
}

if (!connected) {
  console.error("✗ Failed to connect to Chrome");
  process.exit(1);
}

console.log(
  `✓ Chrome started on :9222${useProfile ? " with your profile" : ""}${headful ? " (headful)" : " (headless)"}`,
);
