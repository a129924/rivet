#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

function arg(name) {
  const index = process.argv.indexOf(`--${name}`);
  if (index < 0 || index === process.argv.length - 1) throw new Error(`缺少必要參數：--${name}`);
  return process.argv[index + 1];
}

function once(html, from, to, label) {
  const count = html.split(from).length - 1;
  if (count !== 1) throw new Error(`${label} 必須恰好出現一次，實際為 ${count} 次`);
  return html.replace(from, to);
}

function enhance(source, label) {
  if (source.includes('<!-- HTTP_CLIENT_A11Y:START -->')) return source;
  let html = source;
  html = once(html, '<html lang="en">', '<html lang="zh-Hant">', '文件語言');
  html = once(html, `  html, body {
    margin: 0; padding: 0; height: 100%; overflow: hidden;
    background: var(--bg); color: var(--ink);
    font-family: 'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace;
    -webkit-font-smoothing: antialiased;
  }`, `  html { min-height: 100%; overflow-x: hidden; overflow-y: auto; }
  body {
    margin: 0; padding: 0; min-height: 100vh; overflow-x: hidden; overflow-y: auto;
    background: var(--bg); color: var(--ink);
    font-family: 'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace;
    -webkit-font-smoothing: antialiased;
  }`, '可捲動文件樣式');
  html = once(html, '  #stage { position: fixed; inset: 0; }', `  #stage { position: fixed; inset: 0; }
  #stage:focus-visible { outline: 2px solid var(--accent); outline-offset: -4px; }
  #diagram-fallback {
    position: relative; z-index: 11; width: min(34rem, calc(100vw - 36px));
    margin: 88px 18px 88px auto; border: 1px solid var(--chrome-border);
    border-radius: 12px; background: var(--chrome); color: var(--ink);
  }
  #diagram-fallback summary { cursor: pointer; padding: 11px 13px; font-size: 12px; font-weight: 700; }
  #diagram-fallback .fallback-content { padding: 0 13px 13px; font-size: 12px; line-height: 1.6; }
  #diagram-fallback h2, #diagram-fallback h3 { font-size: 13px; margin: 12px 0 6px; }
  #diagram-fallback ol, #diagram-fallback ul { margin: 0; padding-left: 22px; }
  #diagram-fallback li + li { margin-top: 6px; }
  #diagram-fallback:focus-within, #diagram-fallback summary:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; }`, 'fallback 樣式');
  html = once(html, '<div id="stage"><canvas id="c"></canvas></div>', `<div id="stage" tabindex="0" role="region" aria-label="${label}互動圖" aria-describedby="diagram-operations"><canvas id="c" aria-hidden="true"></canvas></div>

<!-- HTTP_CLIENT_A11Y:START -->
<p id="diagram-operations" style="position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0">此互動圖可用方向鍵平移，0 縮放至符合視窗，1 回到原始大小，T 切換主題，Esc 清除選取。可展開下方文字替代內容以讀取節點與關係。</p>
<section id="diagram-fallback" aria-label="${label}文字替代內容"></section>
<!-- HTTP_CLIENT_A11Y:END -->`, 'stage 標記');
  html = once(html, `<div id="hint">
  <div><kbd>drag / two-finger scroll</kbd> pan &nbsp;·&nbsp; <kbd>pinch</kbd> zoom</div>
  <div><kbd>click</kbd> isolate &nbsp;·&nbsp; <kbd>0</kbd> fit &nbsp;·&nbsp; <kbd>t</kbd> theme &nbsp;·&nbsp; <kbd>esc</kbd> clear</div>
</div>`, `<div id="hint">
  <div><kbd>拖曳／雙指捲動</kbd> 平移 &nbsp;·&nbsp; <kbd>雙指縮放</kbd> 縮放</div>
  <div><kbd>點擊</kbd> 聚焦 &nbsp;·&nbsp; <kbd>0</kbd> 符合視窗 &nbsp;·&nbsp; <kbd>T</kbd> 主題 &nbsp;·&nbsp; <kbd>Esc</kbd> 清除</div>
</div>`, '操作提示');
  html = once(html, '<div class="bar" id="toolbar">', '<div class="bar" id="toolbar" role="toolbar" aria-label="互動圖工具列">', '工具列');
  html = once(html, '  <button id="bOut" title="Zoom out (−)" aria-label="Zoom out">', '  <button id="bOut" title="縮小（−）" aria-label="縮小">', '縮小按鈕');
  html = once(html, '  <button id="bIn" title="Zoom in (+)" aria-label="Zoom in">', '  <button id="bIn" title="放大（+）" aria-label="放大">', '放大按鈕');
  html = once(html, '  <button id="bFit" title="Fit to screen (0)">Fit</button>', '  <button id="bFit" title="符合視窗（0）">符合視窗</button>', '符合視窗按鈕');
  html = once(html, '  <button id="bOne" title="Actual size (1)">1:1</button>', '  <button id="bOne" title="原始大小（1）">1:1</button>', '原始大小按鈕');
  html = once(html, '  <button id="bTheme" title="Light theme (t)" aria-label="Toggle light and dark theme"></button>', '  <button id="bTheme" title="切換淺色與深色主題（T）" aria-label="切換淺色與深色主題"></button>', '主題按鈕');
  html = once(html, '  <button id="bPng" title="Download PNG @2×">', '  <button id="bPng" title="下載 PNG（2 倍）" aria-label="下載 PNG（2 倍）">', 'PNG 按鈕');
  const fallback = `
  function createTextFallback() {
    const target = document.getElementById('diagram-fallback');
    const details = document.createElement('details');
    const summary = document.createElement('summary');
    summary.textContent = '開啟文字替代內容（節點與關係）';
    details.appendChild(summary);
    const content = document.createElement('div');
    content.className = 'fallback-content';
    const nodeTitle = document.createElement('h2');
    nodeTitle.textContent = '節點';
    content.appendChild(nodeTitle);
    const nodes = document.createElement('ol');
    BOXES.forEach(box => {
      const item = document.createElement('li');
      const plane = PLANES[box.plane] || { label: box.plane };
      item.textContent = box.name + '；' + plane.label + '。' + box.about;
      nodes.appendChild(item);
    });
    content.appendChild(nodes);
    const relationTitle = document.createElement('h3');
    relationTitle.textContent = '關係';
    content.appendChild(relationTitle);
    const relations = document.createElement('ul');
    EDGES.forEach(edge => {
      const item = document.createElement('li');
      const from = BOX_BY_ID.get(edge.from);
      const to = BOX_BY_ID.get(edge.to);
      const relationLabel = edge.label ? '：' + edge.label.t : '';
      item.textContent = (from ? from.name : edge.from) + ' → ' + (to ? to.name : edge.to) + relationLabel;
      relations.appendChild(item);
    });
    content.appendChild(relations);
    const annotationTitle = document.createElement('h3');
    annotationTitle.textContent = '圖表註記';
    content.appendChild(annotationTitle);
    const annotations = document.createElement('ul');
    TEXTS.forEach(entry => {
      const text = entry.t || (entry.runs ? entry.runs.map(run => run.t).join('') : '');
      if (!text || entry.s === 'plane') return;
      const item = document.createElement('li');
      item.textContent = text;
      annotations.appendChild(item);
    });
    content.appendChild(annotations);
    details.appendChild(content);
    target.appendChild(details);
  }
`;
  html = once(html, '  // ---- pointer\n', `${fallback}\n  // ---- pointer\n`, 'fallback 函式');
  html = once(html, `  canvas.addEventListener('pointerdown', (e) => {
    canvas.setPointerCapture(e.pointerId);`, `  canvas.addEventListener('pointerdown', (e) => {
    document.getElementById('stage').focus({ preventScroll: true });
    canvas.setPointerCapture(e.pointerId);`, '指標聚焦');
  const oldKeyboard = `  // ---- keyboard
  window.addEventListener('keydown', (e) => {
    if (e.metaKey || e.ctrlKey) return;
    const pan = e.shiftKey ? 220 : 70;
    switch (e.key) {
      case '0': fit(true); break;
      case '1': actualSize(); break;
      case 't': case 'T': toggleTheme(); break;
      case '+': case '=': zoomAt(view.k * 1.3, vw / 2, vh / 2, true); break;
      case '-': case '_': zoomAt(view.k / 1.3, vw / 2, vh / 2, true); break;
      case 'Escape':
        focused = null; readout.classList.remove('on'); schedule(); break;
      case 'ArrowLeft':  view.x += pan; schedule(); break;
      case 'ArrowRight': view.x -= pan; schedule(); break;
      case 'ArrowUp':    view.y += pan; schedule(); break;
      case 'ArrowDown':  view.y -= pan; schedule(); break;
      default: return;
    }
    e.preventDefault();
    hint.classList.add('faded');
  });`;
  const newKeyboard = `  // ---- keyboard
  const stage = document.getElementById('stage');
  stage.addEventListener('keydown', (e) => {
    if (e.target !== stage || e.metaKey || e.ctrlKey) return;
    const pan = e.shiftKey ? 220 : 70;
    switch (e.key) {
      case '0': fit(true); break;
      case '1': actualSize(); break;
      case 't': case 'T': toggleTheme(); break;
      case '+': case '=': zoomAt(view.k * 1.3, vw / 2, vh / 2, true); break;
      case '-': case '_': zoomAt(view.k / 1.3, vw / 2, vh / 2, true); break;
      case 'Escape': focused = null; readout.classList.remove('on'); schedule(); break;
      case 'ArrowLeft': view.x += pan; schedule(); break;
      case 'ArrowRight': view.x -= pan; schedule(); break;
      case 'ArrowUp': view.y += pan; schedule(); break;
      case 'ArrowDown': view.y -= pan; schedule(); break;
      default: return;
    }
    e.preventDefault();
    hint.classList.add('faded');
  });`;
  html = once(html, oldKeyboard, newKeyboard, '鍵盤行為');
  html = once(html, "    themeButton.title = (t === 'dark' ? 'Light' : 'Dark') + ' theme (t)';", "    const nextThemeLabel = t === 'dark' ? '切換為淺色主題（T）' : '切換為深色主題（T）';\n    themeButton.title = nextThemeLabel;\n    themeButton.setAttribute('aria-label', nextThemeLabel);", '主題文字');
  html = once(html, "  if (embedded) pngButton.title = 'Open PNG @2× in a new tab';", "  if (embedded) { pngButton.title = '在新分頁開啟 PNG（2 倍）'; pngButton.setAttribute('aria-label', '在新分頁開啟 PNG（2 倍）'); }", '內嵌 PNG 文字');
  html = once(html, '  // ---- toolbar\n', '  createTextFallback();\n\n  // ---- toolbar\n', 'fallback 初始化');
  return html;
}

try {
  fs.writeFileSync(path.resolve(arg('output')), enhance(fs.readFileSync(path.resolve(arg('input')), 'utf8'), arg('label')));
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
