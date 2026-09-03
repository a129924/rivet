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

  const successOnly = [
    ['validator', 'parser'],
    ['parser', 'renderer'],
    ['renderer', 'output'],
  ];
  for (const [from, to] of successOnly) {
    const entries = flowsFrom(from).filter((entry) => entry.to === to);
    assert(entries.length === 1 && entries[0].classification === 'success', `${from} 只可在 success 時前往 ${to}`);
  }

  const outcomes = [
    {
      from: 'validator',
      label: 'invalid-input',
      classification: 'Facade outcome；終止',
      outcome: 'invalid-input-outcome',
      sublabel: 'invalid-input',
    },
    {
      from: 'parser',
      label: 'parse-error',
      classification: 'Facade outcome；終止',
      outcome: 'parse-error-outcome',
      sublabel: 'parse-error',
    },
    {
      from: 'renderer',
      label: 'render-error',
      classification: 'Facade outcome；終止',
      outcome: 'render-error-outcome',
      sublabel: 'render-error',
    },
    {
      from: 'output',
      label: 'output-error',
      classification: 'Facade outcome；終止',
      outcome: 'output-error-outcome',
      sublabel: 'output-error',
    },
    {
      from: 'output',
      label: '{ type: "success" }',
      classification: 'success',
      outcome: 'success-outcome',
      sublabel: '{ type: "success" }',
    },
  ];
  for (const { from, label, classification, outcome, sublabel } of outcomes) {
    const entries = flowsFrom(from).filter((entry) => entry.to === outcome);
    const node = nodes.get(outcome);
    assert(entries.length === 1 && entries[0].label === label && entries[0].classification === classification, `${label} 必須終止於對應 Facade outcome`);
    assert(node && node.label === 'Facade outcome' && node.sublabel === sublabel, `${label} 必須有對應的 terminal Facade outcome node`);
    assert(flowsFrom(outcome).length === 0, `${label} 的 Facade outcome 必須沒有 downstream edge`);
  }

  const expectedTargets = new Map([
    ['validator', ['parser', 'invalid-input-outcome']],
    ['parser', ['renderer', 'parse-error-outcome']],
    ['renderer', ['output', 'render-error-outcome']],
    ['output', ['output-error-outcome', 'success-outcome']],
  ]);
  for (const [from, targets] of expectedTargets) {
    const allowedTargets = new Set(targets);
    const entries = flowsFrom(from);
    assert(entries.length === allowedTargets.size && entries.every((entry) => allowedTargets.has(entry.to)), `${from} 不得有任何額外、錯向或 failure-to-downstream edge`);
  }
  process.stdout.write(`dataflow contract 驗證通過：${input}\n`);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
