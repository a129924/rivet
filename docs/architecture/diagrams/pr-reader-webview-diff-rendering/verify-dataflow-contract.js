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
  const diagram = JSON.parse(fs.readFileSync(input, 'utf8'));
  const nodes = new Map(diagram.nodes.map((node) => [node.id, node]));
  const flows = diagram.flows;
  const flowsFrom = (from) => flows.filter((entry) => entry.from === from);
  const flow = (from, to) => flowsFrom(from).find((entry) => entry.to === to);

  const successOnly = [
    ['validator', 'parser'],
    ['parser', 'renderer'],
    ['renderer', 'output'],
  ];
  for (const [from, to] of successOnly) {
    const entries = flowsFrom(from).filter((entry) => entry.to === to);
    assert(entries.length === 1 && entries[0].classification === 'success', `${from} 只可在 success 時前往 ${to}`);
  }

  const failures = [
    ['validator', 'invalid-input', 'invalid-input-outcome'],
    ['parser', 'parse-error', 'parse-error-outcome'],
    ['renderer', 'render-error', 'render-error-outcome'],
    ['output', 'output-error', 'output-error-outcome'],
  ];
  for (const [from, kind, outcome] of failures) {
    const entry = flow(from, outcome);
    const node = nodes.get(outcome);
    assert(entry && entry.label === kind && entry.classification === 'Facade outcome；終止', `${kind} 必須終止於對應 Facade outcome`);
    assert(node && node.label === 'Facade outcome' && node.sublabel === kind, `${kind} 必須有對應的 terminal Facade outcome node`);
  }

  for (const [from, kind, outcome] of failures) {
    const next = successOnly.find(([candidate]) => candidate === from)?.[1];
    const allowedTargets = new Set(next ? [next, outcome] : [outcome]);
    const entries = flowsFrom(from);
    assert(entries.length === allowedTargets.size && entries.every((entry) => allowedTargets.has(entry.to)), `${kind} 不得有任何額外或 failure-to-downstream edge`);
  }
  process.stdout.write(`dataflow contract 驗證通過：${input}\n`);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
