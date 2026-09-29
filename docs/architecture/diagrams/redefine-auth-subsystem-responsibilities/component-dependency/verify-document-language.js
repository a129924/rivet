#!/usr/bin/env node
'use strict';

// Independently verifies that delivered HTML differs from its raw canvas build
// by exactly the one allowed document-root language replacement.

const fs = require('fs');

const RAW_ROOT = '<html lang="en">';
const FINAL_ROOT = '<html lang="zh-Hant">';

function fail(message) {
  console.error(`document-language verification failed: ${message}`);
  process.exit(1);
}

function argumentsForInvocation() {
  const args = process.argv.slice(2);
  if (args.length !== 4 || args[0] !== '--raw' || args[2] !== '--final') {
    fail('usage: node verify-document-language.js --raw <raw.html> --final <final.html>');
  }

  if (!args[1] || !args[3]) {
    fail('raw and final paths must be non-empty');
  }

  return { raw: args[1], final: args[3] };
}

function readOrFail(file, label) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch (error) {
    fail(`${label} could not be read: ${error.message}`);
  }
}

function assertExactRoot(html, expected, label) {
  const rootTags = html.match(/<html\b[^>]*>/gi) || [];
  const expectedRoots = html.match(new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || [];

  if (rootTags.length !== 1 || rootTags[0] !== expected || expectedRoots.length !== 1) {
    fail(`${label} must contain exactly one ${expected} and no other html root tag`);
  }
}

const { raw: rawPath, final: finalPath } = argumentsForInvocation();
const raw = readOrFail(rawPath, 'raw HTML');
const finalHtml = readOrFail(finalPath, 'final HTML');

assertExactRoot(raw, RAW_ROOT, 'raw HTML');
assertExactRoot(finalHtml, FINAL_ROOT, 'final HTML');

if (finalHtml.includes(RAW_ROOT)) {
  fail('final HTML must not retain root lang="en"');
}

const expectedFinal = raw.replace(RAW_ROOT, FINAL_ROOT);
if (finalHtml !== expectedFinal) {
  fail('final HTML must differ from raw HTML only by the root lang value');
}

console.log('document language verified: one root <html lang="zh-Hant">; only allowed delta present');
