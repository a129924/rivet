#!/usr/bin/env node
'use strict';

// Converts only the generated document root from the global canvas template's
// fixed English language to this artifact's Traditional Chinese language.
// Any shape other than the exact expected raw root fails before delivery.

const fs = require('fs');
const path = require('path');

const RAW_ROOT = '<html lang="en">';
const FINAL_ROOT = '<html lang="zh-Hant">';

function fail(message) {
  console.error(`document-language enhancement failed: ${message}`);
  process.exit(1);
}

function argumentsForInvocation() {
  const args = process.argv.slice(2);
  if (args.length !== 4 || args[0] !== '--input' || args[2] !== '--output') {
    fail('usage: node enhance-document-language.js --input <raw.html> --output <final.html>');
  }

  if (!args[1] || !args[3]) {
    fail('input and output paths must be non-empty');
  }

  return { input: args[1], output: args[3] };
}

function assertExactRawRoot(html) {
  const rootTags = html.match(/<html\b[^>]*>/gi) || [];
  const expectedRoots = html.match(/<html lang="en">/g) || [];

  if (rootTags.length !== 1 || rootTags[0] !== RAW_ROOT || expectedRoots.length !== 1) {
    fail('input must contain exactly one root <html lang="en"> and no other html root tag');
  }
}

function writeAtomically(output, contents) {
  const resolvedOutput = path.resolve(output);
  const directory = path.dirname(resolvedOutput);
  const temporary = path.join(
    directory,
    `.${path.basename(resolvedOutput)}.${process.pid}.${Date.now()}.document-language.tmp`
  );

  try {
    const descriptor = fs.openSync(temporary, 'wx', 0o644);
    try {
      fs.writeFileSync(descriptor, contents, 'utf8');
      fs.fsyncSync(descriptor);
    } finally {
      fs.closeSync(descriptor);
    }
    fs.renameSync(temporary, resolvedOutput);
  } catch (error) {
    fail(`atomic output was not published: ${error.message}`);
  }
}

const { input, output } = argumentsForInvocation();
let raw;
try {
  raw = fs.readFileSync(input, 'utf8');
} catch (error) {
  fail(`input could not be read: ${error.message}`);
}

assertExactRawRoot(raw);

const finalHtml = raw.replace(RAW_ROOT, FINAL_ROOT);
if (finalHtml === raw || finalHtml !== `${raw.slice(0, raw.indexOf(RAW_ROOT))}${FINAL_ROOT}${raw.slice(raw.indexOf(RAW_ROOT) + RAW_ROOT.length)}`) {
  fail('the final document would differ by more than the one allowed root-language replacement');
}

writeAtomically(output, finalHtml);
console.log('document root language enhanced: en → zh-Hant');
