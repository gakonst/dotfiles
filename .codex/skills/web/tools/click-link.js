#!/usr/bin/env node
import puppeteer from 'puppeteer-core';
import { argv } from 'node:process';

const textToClick = argv[2];
if (!textToClick) {
  console.error('Usage: click-link.js <link-text>');
  process.exit(1);
}

const b = await puppeteer.connect({ browserURL: 'http://localhost:9222', defaultViewport: null });
const p = (await b.pages()).at(-1);

await p.waitForSelector('a', { timeout: 15000 });
const links = await p.$$('a');
let target = null;
for (const link of links) {
  const text = (await p.evaluate(el => el.textContent.trim(), link)).toLowerCase();
  if (text === textToClick.toLowerCase()) {
    target = link;
    break;
  }
}
if (!target) {
  console.error(`Link with text "${textToClick}" not found`);
  await b.disconnect();
  process.exit(1);
}
await target.click();
await p.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 20000 }).catch(() => {});
await new Promise(r => setTimeout(r, 2000));
console.log(`✓ clicked ${textToClick}`);
await b.disconnect();
