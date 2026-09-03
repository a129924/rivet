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
    margin: 18px 18px 88px auto; border: 1px solid var(--chrome-border);
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
    details.appendChild(content);
    target.appendChild(details);
  }
`;
  html = once(html, '  // ---- pointer\n', `${fallback}\n  // ---- pointer\n`, 'fallback 函式');
  html = once(html, '  // ---- toolbar\n', '  createTextFallback();\n\n  // ---- toolbar\n', 'fallback 初始化');
  return html;
}

try {
  fs.writeFileSync(path.resolve(arg('output')), enhance(fs.readFileSync(path.resolve(arg('input')), 'utf8'), arg('label')));
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
