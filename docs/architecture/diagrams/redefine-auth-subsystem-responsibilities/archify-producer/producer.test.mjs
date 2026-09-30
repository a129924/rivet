import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { prepareRuntime, verifyPins, contained, verifyReceipt, run } from './run.mjs';

const producer = path.dirname(fileURLToPath(import.meta.url));
const repository = path.resolve(producer, '../../../../..');
const upstream = process.env.ARCHIFY_UPSTREAM_ROOT || path.join(os.homedir(), '.codex/skills/archify');
const manifest = JSON.parse(fs.readFileSync(path.join(producer, 'upstream-pin.json')));
const fixtures = fs.mkdtempSync(path.join(os.tmpdir(), 'rivet-producer-tests-'));
const runtime = prepareRuntime(upstream);
const sha = data => createHash('sha256').update(data).digest('hex');
const normal = JSON.parse(fs.readFileSync(path.join(repository,
  'docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.json')));
const state = JSON.parse(fs.readFileSync(path.join(repository,
  'docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/auth-flow-state.json')));
const invoke = args => spawnSync(process.execPath, [path.join(producer, 'run.mjs'), ...args],
  { cwd: fixtures, encoding: 'utf8', maxBuffer: 10000000 });
test.after(() => {
  fs.rmSync(runtime, { recursive: true, force: true });
  fs.rmSync(fixtures, { recursive: true, force: true });
});
test('manifest pins cover every copied runtime byte, including readonly generator dependencies', () => {
  let count = 0;
  function walk(dir) {
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) walk(full);
      else {
        const relative = path.relative(runtime, full).split(path.sep).join('/');
        assert.ok(manifest.files[relative], relative);
        count++;
      }
    }
  }
  walk(runtime);
  assert.equal(count, Object.keys(manifest.files).length);
  for (const relative of ['package.json', 'schemas/common.schema.json', 'scripts/generate-validators.mjs', 'bin/archify.mjs'])
    assert.equal(sha(fs.readFileSync(path.join(runtime, relative))), manifest.files[relative]);
});
test('complete five-target patch is deterministic and generated validator is consistent', () => {
  const patch = fs.readFileSync(path.join(producer, 'document-language.patch'), 'utf8');
  assert.deepEqual([...patch.matchAll(/^\+\+\+ b\/(.+)$/gm)].map(m => m[1]), [
    'schemas/sequence.schema.json', 'schemas/lifecycle.schema.json',
    'renderers/shared/generated-validators.mjs', 'renderers/shared/cli.mjs', 'renderers/shared/utils.mjs'
  ]);
  assert.equal(spawnSync(process.execPath, ['scripts/generate-validators.mjs', '--check'], { cwd: runtime }).status, 0);
  const repeat = prepareRuntime(upstream);
  try {
    for (const relative of Object.keys(manifest.files))
      assert.equal(sha(fs.readFileSync(path.join(runtime, relative))), sha(fs.readFileSync(path.join(repeat, relative))), relative);
  } finally { fs.rmSync(repeat, { recursive: true, force: true }); }
});
test('default/en/zh-CN Viewer catalog stays unchanged while sequence/lifecycle roots support zh-Hant', async () => {
  const { applyTemplate } = await import(pathToFileURL(path.join(runtime, 'renderers/shared/utils.mjs')));
  const { svgRootAttrs } = await import(pathToFileURL(path.join(runtime, 'renderers/shared/cli.mjs')));
  const { validateSchema } = await import(pathToFileURL(path.join(runtime, 'renderers/shared/validator.mjs')));
  const template = fs.readFileSync(path.join(runtime, 'assets/template.html'), 'utf8');
  for (const type of ['sequence', 'lifecycle']) {
    for (const locale of [undefined, 'en', 'zh-CN']) {
      const diagram = structuredClone(type === 'sequence' ? normal : state);
      delete diagram.meta.document_language;
      if (locale) diagram.meta.locale = locale; else delete diagram.meta.locale;
      validateSchema(type, diagram);
      const language = locale || 'en';
      const baseline = applyTemplate(template, { title: '測試', svg: '<svg></svg>', cards: '', locale });
      const override = applyTemplate(template, { title: '測試', svg: '<svg></svg>', cards: '', locale, documentLanguage: 'zh-Hant' });
      assert.match(baseline, new RegExp('<html lang="' + language + '"'));
      assert.match(override, /<html lang="zh-Hant"/);
      // Only root lang differs: exact Viewer strings, localized title and i18n data remain byte-identical.
      assert.equal(override.replace('<html lang="zh-Hant"', '<html lang="' + language + '"'), baseline);
      assert.match(svgRootAttrs(diagram.meta, type), new RegExp('lang="' + language + '"'));
      diagram.meta.document_language = 'zh-Hant';
      validateSchema(type, diagram);
      assert.match(svgRootAttrs(diagram.meta, type), /lang="zh-Hant"/);
    }
  }
});
test('invalid document languages fail before any output or delivery receipt', () => {
  for (const type of ['sequence', 'lifecycle']) {
    for (const language of ['en', 'zh-CN', 'fr', '', null, 42]) {
      const diagram = structuredClone(type === 'sequence' ? normal : state);
      diagram.meta.document_language = language;
      fs.writeFileSync(path.join(fixtures, 'invalid.json'), JSON.stringify(diagram));
      const result = invoke(['deliver', type, 'invalid.json', 'invalid.html', '--repo-root', '.', '--quality', 'showcase']);
      assert.notEqual(result.status, 0);
      assert.equal(fs.existsSync(path.join(fixtures, 'invalid.html')), false);
      assert.equal(fs.existsSync(path.join(fixtures, 'invalid.delivery.json')), false);
      assert.equal(fs.readdirSync(fixtures).some(file => file.startsWith('.archify-')), false);
    }
  }
});
test('a readonly dependency pin mismatch fails closed before output', async () => {
  const changed = structuredClone(manifest);
  changed.files['bin/visual-check.mjs'] = '0'.repeat(64);
  assert.throws(() => verifyPins(fs.realpathSync(upstream), changed), /pin mismatch/);
  assert.throws(() => prepareRuntime(upstream, changed), /pin mismatch/);
  fs.writeFileSync(path.join(fixtures, 'pin-input.json'), JSON.stringify(normal));
  const previousCwd = process.cwd();
  process.chdir(fixtures);
  try {
    await assert.rejects(run(['deliver', 'sequence', 'pin-input.json', 'pin-output.html',
      '--repo-root', '.', '--quality', 'showcase'], { upstream, manifest: changed }), /pin mismatch/);
    assert.equal(fs.existsSync('pin-output.html'), false);
    assert.equal(fs.existsSync('pin-output.delivery.json'), false);
    assert.equal(fs.readdirSync('.').some(file => file.startsWith('.archify-')), false);
  } finally { process.chdir(previousCwd); }
});
test('canonical input/output/root symlink boundaries and traversal defenses are retained', () => {
  const root = fs.realpathSync(fixtures);
  fs.writeFileSync(path.join(fixtures, 'input.json'), JSON.stringify(normal));
  const outside = fs.mkdtempSync(path.join(os.tmpdir(), 'rivet-producer-outside-'));
  try {
    fs.writeFileSync(path.join(outside, 'external.json'), JSON.stringify(normal));
    fs.symlinkSync(outside, path.join(fixtures, 'escape'));
    assert.throws(() => contained(root, '../escape.html'), /relative/);
    assert.throws(() => contained(root, path.join(outside, 'external.json'), true), /relative/);
    assert.throws(() => contained(root, 'escape/external.json', true), /escapes/);
    assert.throws(() => contained(root, 'escape/new.html'), /escapes/);
    for (const [input, output] of [
      ['escape/external.json', 'bad.html'], ['input.json', 'escape/new.html'],
      [path.join(outside, 'external.json'), 'bad.html'], ['input.json', path.join(outside, 'new.html')]
    ]) {
      assert.notEqual(invoke(['deliver', 'sequence', input, output, '--repo-root', '.']).status, 0);
    }
    assert.notEqual(invoke(['deliver', 'sequence', 'input.json', 'bad.html', '--repo-root', 'escape']).status, 0);
    assert.notEqual(invoke(['deliver', 'sequence', 'input.json', 'bad.html', '--repo-root', '.', '--repo-root', 'escape']).status, 0);
    assert.equal(fs.existsSync(path.join(fixtures, 'bad.html')), false);
    assert.equal(fs.existsSync(path.join(fixtures, 'bad.delivery.json')), false);
    assert.equal(fs.existsSync(path.join(outside, 'new.html')), false);
    const rootAlias = path.join(outside, 'root');
    fs.symlinkSync(fixtures, rootAlias);
    assert.equal(fs.realpathSync(rootAlias), root);
    assert.equal(contained(fs.realpathSync(rootAlias), 'input.json', true), path.join(root, 'input.json'));
  } finally { fs.rmSync(outside, { recursive: true, force: true }); }
});
test('standard deliver captures exact producer stdout bytes and verifies bound hashes/counts', () => {
  fs.writeFileSync(path.join(fixtures, 'valid.json'), JSON.stringify(normal));
  const result = invoke(['deliver', 'sequence', 'valid.json', 'valid.html', '--repo-root', '.', '--quality', 'showcase', '--json']);
  assert.equal(result.status, 0, result.stderr + result.stdout);
  const captured = fs.readFileSync(path.join(fixtures, 'valid.delivery.json'));
  assert.equal(captured.toString('utf8'), result.stdout);
  const receipt = verifyReceipt(captured, fs.realpathSync(fixtures), 'valid.json', 'valid.html');
  assert.equal(receipt.validation.checkCount, 9);
  const html = fs.readFileSync(path.join(fixtures, 'valid.html'), 'utf8');
  assert.match(html, /<html lang="zh-Hant"/);
  assert.match(html, /<svg[^>]*lang="zh-Hant"/);
  const badHash = structuredClone(receipt);
  badHash.artifact.sha256 = '0'.repeat(64);
  assert.throws(() => verifyReceipt(Buffer.from(JSON.stringify(badHash)), fs.realpathSync(fixtures), 'valid.json', 'valid.html'), /hash mismatch/);
  const badPath = structuredClone(receipt);
  badPath.provenance = { path: '/outside/local' };
  assert.throws(() => verifyReceipt(Buffer.from(JSON.stringify(badPath)), fs.realpathSync(fixtures), 'valid.json', 'valid.html'), /relative/);
  assert.equal(fs.readdirSync(fixtures).some(file => file.startsWith('.archify-')), false);
  fs.writeFileSync(path.join(fixtures, 'lifecycle.json'), JSON.stringify(state));
  const lifecycle = invoke(['deliver', 'lifecycle', 'lifecycle.json', 'lifecycle.html', '--repo-root', '.', '--quality', 'showcase', '--json']);
  assert.equal(lifecycle.status, 0, lifecycle.stderr + lifecycle.stdout);
  const lifecycleBytes = fs.readFileSync(path.join(fixtures, 'lifecycle.delivery.json'));
  assert.equal(lifecycleBytes.toString('utf8'), lifecycle.stdout);
  verifyReceipt(lifecycleBytes, fs.realpathSync(fixtures), 'lifecycle.json', 'lifecycle.html');
  const lifecycleHTML = fs.readFileSync(path.join(fixtures, 'lifecycle.html'), 'utf8');
  assert.match(lifecycleHTML, /<html lang="zh-Hant"/);
  assert.match(lifecycleHTML, /<svg[^>]*lang="zh-Hant"/);
});
