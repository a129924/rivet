#!/usr/bin/env node
'use strict';

// Adds a safely escaped, scene-derived static alternative to the canvas and
// changes its root language. The generated scene and viewer remain untouched.

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const RAW_ROOT = '<html lang="en">';
const FINAL_ROOT = '<html lang="zh-Hant">';
const START = '<!-- component semantic content start -->';
const END = '<!-- component semantic content end -->';

function semanticContent(raw) {
  const begin = '// ======================== SCENE START (generated) =========================';
  const end = '// ========================= SCENE END ======================================';
  if (raw.split(begin).length !== 2 || raw.split(end).length !== 2 ||
      raw.indexOf(begin) >= raw.indexOf(end) || raw.includes(START) || raw.includes(END) ||
      raw.split('</body>').length !== 2) fail('scene/body markers must be unique and ordered');
  const code = raw.slice(raw.indexOf(begin) + begin.length, raw.indexOf(end));
  const scene = vm.runInNewContext(code + '\n;({BOXES, EDGES, TEXTS, BANDS, PLANES})',
    { C: {}, planeColor: () => '' }, { timeout: 1000 });
  if (scene.BOXES.length !== 10 || scene.EDGES.length !== 12 ||
      new Set(scene.BOXES.map(box => box.id)).size !== 10)
    fail('expected complete ten-node/twelve-edge scene');
  const escape = text => String(text).replace(/[&<>"']/g,
    character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character]));
  const names = Object.fromEntries(scene.BOXES.map(box => [box.id, box.name]));
  const nodes = scene.BOXES.map(box => '<li><strong>' + escape(box.name) + '</strong><p>' +
    escape(box.about) + '</p><ul>' + box.texts.map(text => '<li>' + escape(text[3]) + '</li>').join('') +
    '</ul></li>').join('');
  const edges = scene.EDGES.map(edge => {
    if (!names[edge.from] || !names[edge.to]) fail('edge references unknown node');
    return '<li>' + escape(names[edge.from]) + ' → ' + escape(names[edge.to]) +
      (edge.label ? '：' + escape(edge.label.t) : '') + '</li>';
  }).join('');
  const context = [...Object.values(scene.PLANES).map(plane => plane.label),
    ...scene.BANDS.flatMap(band => [band.hdr?.t, band.tagr?.t].filter(Boolean)),
    ...scene.TEXTS.map(text => text.t || text.runs.map(run => run.t).join(''))];
  return START + '\n<style>\n#component-semantics{position:fixed;right:24px;bottom:72px;width:300px;max-height:112px;overflow:auto;z-index:5;padding:12px;border:1px solid var(--chrome-border);border-radius:8px;background:var(--bg);color:var(--ink);font:12px/1.5 monospace}#component-semantics:focus{outline:2px solid currentColor}#component-semantics h2,#component-semantics h3,#component-semantics p{margin:0 0 8px}#component-semantics ul,#component-semantics ol{padding-left:20px}\n</style>\n' +
    '<section id="component-semantics" tabindex="0" aria-labelledby="component-semantics-title">' +
    '<h2 id="component-semantics-title">架構等價文字</h2><h3>元件</h3><ul>' + nodes +
    '</ul><h3>有向依賴</h3><ol>' + edges + '</ol><h3>脈絡與限制</h3><ul>' +
    context.map(text => '<li>' + escape(text) + '</li>').join('') + '</ul></section>\n' + END + '\n';
}

function fail(message) {
  console.error(`document-language enhancement failed: ${sanitizeDiagnostic(message)}`);
  process.exit(1);
}

function sanitizeDiagnostic(message) {
  // A quoted path may include spaces or newlines: redact its whole content.
  // Unquoted paths have no trustworthy end delimiter, so redact to line end.
  const absolute = /(^|[^a-zA-Z0-9_.\\/-])(?:[a-zA-Z]:[\\/]|[\\/])/;
  const quoted = String(message).replace(/(["'`])([\s\S]*?)\1/g,
    (_, quote, content) => quote + (absolute.test(content) ? '[local path]' : content) + quote);
  return quoted.replace(/(^|[^a-zA-Z0-9_.\\/-])(?:[a-zA-Z]:[\\/]|[\\/])[^\r\n]*/g,
    '$1[local path]');
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

try {
  assertExactRawRoot(raw);
  const finalHtml = raw.replace(RAW_ROOT, FINAL_ROOT).replace('</body>', semanticContent(raw) + '</body>');
  writeAtomically(output, finalHtml);
  console.log('document language and ten-node/twelve-edge equivalent semantics enhanced');
} catch (error) {
  // Do not let VM errors expose source snippets or local stack filenames.
  fail(`scene enhancement was not published: ${error.message}`);
}
