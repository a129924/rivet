#!/usr/bin/env node
'use strict';

const fs = require('fs');
const input = process.argv[process.argv.indexOf('--input') + 1];
const html = fs.readFileSync(input, 'utf8');
function assert(condition, message) { if (!condition) throw new Error(`驗證失敗：${message}`); }
try {
  assert(html.includes('<html lang="zh-Hant">'), '文件語言必須是繁體中文');
  assert(html.includes('<!-- HTTP_CLIENT_A11Y:START -->') && html.includes('<!-- HTTP_CLIENT_A11Y:END -->'), '必須有 fallback 標記');
  assert(html.includes('tabindex="0" role="region"') && html.includes('aria-describedby="diagram-operations"'), 'stage 必須是可聚焦 region');
  assert(html.includes('<canvas id="c" aria-hidden="true">'), 'canvas 必須對輔助技術隱藏');
  assert(html.includes('BOXES.forEach(box =>') && html.includes('EDGES.forEach(edge =>'), 'fallback 必須由 runtime scene 資料產生');
  assert(html.includes("(from ? from.name : edge.from) + ' → ' + (to ? to.name : edge.to)"), '每個關係必須包含來源、方向與目標');
  assert(html.includes('#diagram-fallback {') && html.includes('position: relative; z-index: 11;'), 'fallback 必須在正常文件流');
  process.stdout.write(`可近用性驗證通過：${input}\n`);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
