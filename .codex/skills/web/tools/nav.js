#!/usr/bin/env node

import puppeteer from "puppeteer-core";

const args = process.argv.slice(2);
let url = null;
let newTab = false;
let auth = null;

for (const arg of args) {
  if (arg === "--new") {
    newTab = true;
  } else if (arg.startsWith("--auth=")) {
    const raw = arg.slice("--auth=".length);
    const [username, ...rest] = raw.split(":");
    auth = { username, password: rest.join(":") };
  } else if (!url) {
    url = arg;
  }
}

if (!auth) {
  const envAuth = process.env.HTTP_BASIC_AUTH || process.env.BASIC_AUTH;
  if (envAuth) {
    const [username, ...rest] = envAuth.split(":");
    auth = { username, password: rest.join(":") };
  }
}

if (!url) {
  console.log("Usage: nav.js <url> [--new] [--auth=username:password]");
  console.log("\nExamples:");
  console.log("  nav.js https://example.com                   # Navigate current tab");
  console.log("  nav.js https://example.com --new             # Open in new tab");
  console.log("  nav.js https://secure.example.com --auth=user:pass");
  console.log("  BASIC_AUTH=user:pass nav.js https://secure.example.com");
  process.exit(1);
}

const b = await puppeteer.connect({
  browserURL: "http://localhost:9222",
  defaultViewport: null,
});

const pageOrNull = (await b.pages()).at(-1);
let p = pageOrNull;

if (newTab || !p) {
  p = await b.newPage();
}

if (auth?.username) {
  await p.authenticate(auth);
}

await p.goto(url, { waitUntil: "domcontentloaded" });

console.log(newTab ? "✓ Opened:" : "✓ Navigated to:", url);

await b.disconnect();
