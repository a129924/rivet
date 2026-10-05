#!/usr/bin/env node
'use strict';

// Independently checks the complete escaped scene projection, bounded CSS and
// root language, then requires every original viewer byte to remain unchanged.

const fs = require('fs');
const vm = require('vm');

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

const start = '<!-- component semantic content start -->';
const end = '<!-- component semantic content end -->\n';
const beginScene = '// ======================== SCENE START (generated) =========================';
const endScene = '// ========================= SCENE END ======================================';
for (const marker of [beginScene, endScene, '</body>']) {
  if (raw.split(marker).length !== 2) fail('raw scene/body markers must be unique');
}
if (raw.indexOf(beginScene) >= raw.indexOf(endScene)) fail('raw scene markers must be ordered');
if (raw.includes(start) || raw.includes(end) || finalHtml.split(start).length !== 2 ||
    finalHtml.split(end).length !== 2 || finalHtml.indexOf(start) >= finalHtml.indexOf(end))
  fail('semantic markers must be unique and ordered');
const offset = finalHtml.indexOf(start);
const limit = finalHtml.indexOf(end) + end.length;
if (finalHtml.slice(limit, limit + 7) !== '</body>' ||
    finalHtml.slice(0, offset) + finalHtml.slice(limit) !== raw.replace(RAW_ROOT, FINAL_ROOT))
  fail('only root language and the one adjacent static semantic block may differ');
const scene = vm.runInNewContext(raw.slice(raw.indexOf(beginScene) + beginScene.length,
  raw.indexOf(endScene)) + '\n;({BOXES, EDGES, TEXTS, BANDS, PLANES})',
  { C: {}, planeColor: () => '' }, { timeout: 1000 });
if (scene.BOXES.length !== 10 || scene.EDGES.length !== 12 ||
    new Set(scene.BOXES.map(box => box.id)).size !== 10) fail('incomplete scene');
const esc = value => String(value).replace(/[&<>"']/g,
  c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const names = Object.fromEntries(scene.BOXES.map(box => [box.id, box.name]));
const nodeList = scene.BOXES.map(box => `<li><strong>${esc(box.name)}</strong><p>${esc(box.about)}</p><ul>` +
  box.texts.map(line => `<li>${esc(line[3])}</li>`).join('') + '</ul></li>').join('');
const edgeList = scene.EDGES.map(edge => {
  if (!names[edge.from] || !names[edge.to]) fail('invalid edge endpoint');
  return `<li>${esc(names[edge.from])} → ${esc(names[edge.to])}` +
    (edge.label ? `：${esc(edge.label.t)}` : '') + '</li>';
}).join('');
const context = [...Object.values(scene.PLANES).map(p => p.label),
  ...scene.BANDS.flatMap(b => [b.hdr?.t, b.tagr?.t].filter(Boolean)),
  ...scene.TEXTS.map(t => t.t || t.runs.map(r => r.t).join(''))];
const expectedSection = '<section id="component-semantics" tabindex="0" aria-labelledby="component-semantics-title">' +
  '<h2 id="component-semantics-title">架構等價文字</h2><h3>元件</h3><ul>' + nodeList +
  '</ul><h3>有向依賴</h3><ol>' + edgeList + '</ol><h3>脈絡與限制</h3><ul>' +
  context.map(t => `<li>${esc(t)}</li>`).join('') + '</ul></section>\n';
const block = finalHtml.slice(offset, limit);
const sectionStart = block.indexOf('<section ');
if (sectionStart < 0 || block.slice(sectionStart, -end.length) !== expectedSection)
  fail('semantic DOM is not the complete safely escaped scene projection');
const expectedStyle = start + '\n<style>\n#component-semantics{position:fixed;right:24px;bottom:72px;width:300px;max-height:112px;overflow:auto;z-index:5;padding:12px;border:1px solid var(--chrome-border);border-radius:8px;background:var(--bg);color:var(--ink);font:12px/1.5 monospace}#component-semantics:focus{outline:2px solid currentColor}#component-semantics h2,#component-semantics h3,#component-semantics p{margin:0 0 8px}#component-semantics ul,#component-semantics ol{padding-left:20px}\n</style>\n';
if (block.slice(0, sectionStart) !== expectedStyle) fail('unexpected semantic attributes or CSS');

console.log('document language and complete equivalent semantic DOM verified; raw viewer unchanged');
