#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

function arg(name) {
  const index = process.argv.indexOf(`--${name}`);
  if (index < 0 || index === process.argv.length - 1) throw new Error(`缺少必要參數：--${name}`);
  return process.argv[index + 1];
}

function assert(condition, message) {
  if (!condition) throw new Error(`驗證失敗：${message}`);
}

try {
  const input = path.resolve(arg('input'));
  const html = fs.readFileSync(input, 'utf8');
  const count = (value) => html.split(value).length - 1;

  assert(count('<!-- PR_READER_A11Y:START -->') === 1 && count('<!-- PR_READER_A11Y:END -->') === 1, '補強標記必須恰好一組');
  assert(html.includes('<html lang="zh-Hant">'), '文件語言必須是繁體中文');
  assert(html.includes('id="stage" tabindex="0" role="region"'), 'stage 必須是可聚焦 region');
  assert(html.includes('aria-describedby="diagram-operations"'), 'stage 必須描述操作方式');
  assert(html.includes('<canvas id="c" aria-hidden="true">'), 'canvas 必須對輔助技術隱藏');
  assert(!html.includes('role="application"'), '不得使用 application role');
  assert(!html.includes("window.addEventListener('keydown'"), '不得使用 window-global keydown');
  assert(html.includes("stage.addEventListener('keydown'"), 'viewport keys 必須由 stage 處理');
  assert(html.includes('e.target !== stage'), '不得攔截 interactive children 的鍵盤操作');
  assert(html.includes("case '[': selectRelativeBox(-1);") && html.includes("case ']': selectRelativeBox(1);"), '必須支援依 BOXES 巡覽');
  assert(html.includes('role="status" aria-live="polite" aria-atomic="true"'), 'readout 必須是 polite live status');
  assert(html.includes('BOXES.forEach((box, index) =>') && html.includes('EDGES.forEach(edge =>'), 'fallback 必須由 runtime scene 資料生成');
  assert(html.includes("button.addEventListener('focus', () => selectBox(box.id, true))") && html.includes("button.addEventListener('click', () => selectBox(box.id, true))"), 'fallback controls 必須共用選取行為');
  assert(html.includes('class="sr-only"') && !html.includes('#diagram-fallback { display: none'), 'fallback 必須保留給輔助技術');
  assert(!html.includes('Zoom out') && !html.includes('Fit to screen') && !html.includes('Toggle light and dark theme'), 'viewer UI 不得保留英文操作文字');
  process.stdout.write(`可近用性驗證通過：${input}\n`);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
