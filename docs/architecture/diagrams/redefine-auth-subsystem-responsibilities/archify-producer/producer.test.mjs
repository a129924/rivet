import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import childProcess from 'node:child_process';
import { syncBuiltinESMExports } from 'node:module';
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
// Inject synthetic filesystem failures into the real CLI entry/catch without
// reading a machine path or invoking a generator. Diagnostic text is data only.
const diagnostic = (message, schema = false) => spawnSync(process.execPath,
  ['--input-type=module', '-e', `
    import fs from 'node:fs';
    import { pathToFileURL } from 'node:url';
    const originalRealpath = fs.realpathSync;
    fs.realpathSync = (...args) => {
      if (!String(args[0]).endsWith('__synthetic_root__')) return originalRealpath(...args);
      const error = new Error(process.env.SYNTHETIC_DIAGNOSTIC);
      if (process.env.SYNTHETIC_SCHEMA === 'yes') error.archifyDiagnostics = [];
      throw error;
    };
    process.argv[1] = process.env.PRODUCER_ENTRY;
    process.argv.push('--repo-root', '__synthetic_root__');
    await import(pathToFileURL(process.argv[1]));
  `], { cwd: fixtures, encoding: 'utf8', env: { ...process.env,
    PRODUCER_ENTRY: path.join(producer, 'run.mjs'), SYNTHETIC_DIAGNOSTIC: message,
    SYNTHETIC_SCHEMA: schema ? 'yes' : 'no' } });
test('CLI diagnostics redact arbitrary POSIX and Windows paths, including quoted spaces', () => {
  const paths = ['/outside/local', '/opt/synthetic/input.json', '/',
    'C:\\synthetic\\input.json', 'D:/synthetic/input.json',
    '\\\\server\\share\\input.json', '\\synthetic\\input.json',
    '/outside/synthetic directory/input.json', 'C:\\synthetic directory\\input.json'];
  for (const value of paths) {
    for (const message of [
      'ENOENT: open ' + value,
      'ENOENT: open "' + value + '"; safe context',
      "ENOENT: open '" + value + "'; safe context",
      'ENOENT: open `' + value + '`; safe context',
      'ENOENT: source=' + value,
      'ENOENT: [' + value + ']',
      'ENOENT: source->' + value,
      'ENOENT: first line\n' + value
    ]) {
      const result = diagnostic(message);
      assert.equal(result.status, 1);
      assert.equal(result.stdout, '');
      assert.match(result.stderr, /^ENOENT: /);
      assert.match(result.stderr, /\[local path\]/);
      assert.equal(result.stderr.includes(value), false, 'Synthetic path must be absent.');
      if (message.endsWith('safe context')) assert.match(result.stderr, /safe context/);
    }
  }
  const relative = 'Upstream pin mismatch: renderers/shared/utils.mjs';
  assert.equal(diagnostic(relative).stderr, relative + '\n');
  const schema = diagnostic('Unsafe schema context /outside/synthetic source.json', true);
  assert.equal(schema.status, 1);
  assert.equal(schema.stderr, 'Source schema validation failed.\n');
});
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
test('receipt metadata rejects unsafe paths recursively, including command arguments and arbitrary keys', () => {
  const input = 'docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.json';
  const output = input.replace(/\.json$/, '.html');
  const original = fs.readFileSync(path.join(repository, input.replace(/\.json$/, '.delivery.json')));
  const preserved = Buffer.from(original);
  const receipt = verifyReceipt(original, repository, input, output);
  const placements = [
    value => ({ provenance: { cwd: value } }),
    value => ({ provenance: { root: value } }),
    value => ({ provenance: { temp: value } }),
    value => ({ provenance: { nested: { records: [{ anything: value }] } } }),
    value => ({ metadata: { nested: [[value]] } }),
    value => ({ metadata: { nested: [{ [value]: 'relative/file.json' }] } }),
    value => ({ commandMetadata: { argv: ['node', '--source=' + value] } }),
    value => ({ commandMetadata: { command: 'node tool.mjs --root "' + value + '"' } }),
    value => ({ commandMetadata: { command: 'node tool.mjs --root=`' + value + '`' } }),
    value => ({ commandMetadata: { command: "node tool.mjs --root='" + value + "'" } })
  ];
  const unsafe = ['cwd:/outside/synthetic', 'custom:/synthetic/local', 'nested:cwd:/synthetic/local',
    'prefix:C:\\outside\\local', 'prefix:\\\\server\\share\\local',
    'prefix:\\outside\\local', '/outside/local', 'C:\\outside\\local', 'D:/outside/local',
    'C:drive-relative', '\\\\server\\share\\local', '//server/share/local',
    '\\outside\\local', '../outside', 'nested/../outside', 'nested\\..\\outside',
    'cwd:../outside', 'root:..\\outside', 'nested:cwd:../outside',
    'nested:cwd:docs/../outside', 'root:docs\\..\\outside'];
  for (const value of unsafe) {
    for (const place of placements) {
      const bytes = Buffer.from(JSON.stringify({ ...receipt, ...place(value) }));
      assert.throws(() => verifyReceipt(bytes, repository, input, output), /relative/, JSON.stringify(place(value)));
    }
  }
  for (const value of ['docs/relative/file.json', './docs/file.json', 'nested\\relative\\file.json',
    'cwd:docs/relative.json', 'status:ready', 'time:12:30', 'urn:synthetic:record']) {
    for (const place of placements) {
      const bytes = Buffer.from(JSON.stringify({ ...receipt, ...place(value) }));
      const before = Buffer.from(bytes);
      verifyReceipt(bytes, repository, input, output);
      assert.deepEqual(bytes, before);
    }
  }
  assert.deepEqual(original, preserved);
});
test('backtick-framed command paths reject unsafe values and preserve valid relative metadata bytes', () => {
  const input = 'docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json';
  const output = input.replace(/\.json$/, '.html');
  const original = fs.readFileSync(path.join(repository, input.replace(/\.json$/, '.delivery.json')));
  const before = Buffer.from(original);
  const receipt = verifyReceipt(original, repository, input, output);
  const framed = value => Buffer.from(JSON.stringify({ ...receipt,
    commandMetadata: { command: 'node tool.mjs --arg=`' + value + '`' } }));
  // These are metadata strings only; the test never executes these commands.
  const accepted = [];
  for (const value of ['/outside/local', 'C:\\outside\\local', '../outside']) {
    try { verifyReceipt(framed(value), repository, input, output); accepted.push(value); }
    catch (error) { assert.match(error.message, /relative/); }
  }
  assert.deepEqual(accepted, [], 'Unsafe backtick-framed paths must be rejected.');
  for (const value of ['docs/relative/file.json', './docs/file.json', 'nested\\relative\\file.json']) {
    const bytes = framed(value);
    const preserved = Buffer.from(bytes);
    verifyReceipt(bytes, repository, input, output);
    assert.deepEqual(bytes, preserved);
  }
  assert.deepEqual(original, before);
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
test('receipt envelope version and type bind to the actual contained source', () => {
  for (const input of [
    'docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.json',
    'docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json'
  ]) {
    const output = input.replace(/\.json$/, '.html');
    const original = fs.readFileSync(path.join(repository, input.replace(/\.json$/, '.delivery.json')));
    const receipt = verifyReceipt(original, repository, input, output);
    for (const [key, values] of [
      ['schemaVersion', [999, '1', null, undefined]],
      ['type', [receipt.type === 'sequence' ? 'lifecycle' : 'sequence', 'unknown', null, undefined]]
    ]) for (const value of values) {
      const bad = { ...receipt, [key]: value };
      assert.throws(() => verifyReceipt(Buffer.from(JSON.stringify(bad)), repository, input, output), /schema|type/i);
    }
    const preserved = Buffer.from(original);
    assert.throws(() => verifyReceipt(original, repository, input, output,
      receipt.type === 'sequence' ? 'lifecycle' : 'sequence'), /type/i);
    assert.deepEqual(original, preserved);
  }
  const original = JSON.parse(fs.readFileSync(path.join(fixtures, 'valid.delivery.json')));
  const actual = fs.readFileSync(path.join(fixtures, 'valid.json'));
  try {
    for (const source of ['{invalid', JSON.stringify({}), JSON.stringify({ diagram_type: 'unknown' })]) {
      fs.writeFileSync(path.join(fixtures, 'valid.json'), source);
      assert.throws(() => verifyReceipt(Buffer.from(JSON.stringify(original)), fixtures, 'valid.json', 'valid.html'));
    }
  } finally { fs.writeFileSync(path.join(fixtures, 'valid.json'), actual); }
});
test('run rejects a source/invocation discriminator mismatch before any artifact publication', () => {
  fs.writeFileSync(path.join(fixtures, 'wrong-invocation.json'), JSON.stringify(normal));
  const previous = Buffer.from('previous output');
  fs.writeFileSync(path.join(fixtures, 'wrong-invocation.html'), previous);
  const result = invoke(['deliver', 'lifecycle', 'wrong-invocation.json', 'wrong-invocation.html', '--repo-root', '.']);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Source\/invocation type mismatch/);
  assert.deepEqual(fs.readFileSync(path.join(fixtures, 'wrong-invocation.html')), previous);
  assert.equal(fs.existsSync(path.join(fixtures, 'wrong-invocation.delivery.json')), false);
});

const component = path.join(repository, 'docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/component-dependency');
const enhance = path.join(component, 'enhance-document-language.js');
const rawCanvas = path.join(fixtures, 'canvas-raw.html');
test('enhancer normal generation preserves exact existing final bytes and readonly verifier contract', () => {
  const skill = path.join(os.homedir(), '.codex/skills/architecture-canvas/scripts');
  const scene = path.join(component, 'scene.js');
  assert.equal(spawnSync(process.execPath, [path.join(skill, 'validate.js'), scene]).status, 0);
  const built = spawnSync(process.execPath, [path.join(skill, 'build.js'), '--scene', scene, '--out', rawCanvas,
    '--title', 'RivetHTTPClient — 認證責任目標', '--kicker', 'RivetHTTPClient — 認證責任目標',
    '--sub', '<b>AuthRequester</b> 持有原始請求 → <b>AuthFlow</b> 擁有策略／狀態 → <b>Requester</b> 執行通用輸入／輸出',
    '--slug', 'redefine-auth-subsystem-responsibilities-component-dependency'], { encoding: 'utf8' });
  assert.equal(built.status, 0, built.stderr);
  const final = path.join(fixtures, 'canvas-final.html');
  const result = spawnSync(process.execPath, [enhance, '--input', rawCanvas, '--output', final], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(fs.readFileSync(final), fs.readFileSync(path.join(component, 'index.html')));
  const verified = spawnSync(process.execPath, [path.join(component, 'verify-document-language.js'),
    '--raw', rawCanvas, '--final', final], { encoding: 'utf8' });
  assert.equal(verified.status, 0, verified.stderr);
});
test('enhancer read, output and VM diagnostics redact paths without publishing failed output', () => {
  const output = path.join(fixtures, 'preserved-canvas.html');
  const before = Buffer.from('previous output');
  fs.writeFileSync(output, before);
  const missing = path.join(fixtures, 'missing synthetic directory', 'input.html');
  const readFailure = spawnSync(process.execPath, [enhance, '--input', missing, '--output', output], { encoding: 'utf8' });
  assert.equal(readFailure.status, 1);
  assert.equal(readFailure.stderr.includes(missing), false);
  assert.deepEqual(fs.readFileSync(output), before);
  const directoryOutput = path.join(fixtures, 'existing output directory');
  fs.mkdirSync(directoryOutput);
  fs.writeFileSync(path.join(directoryOutput, 'preserved'), before);
  const outputFailure = spawnSync(process.execPath, [enhance, '--input', rawCanvas, '--output', directoryOutput], { encoding: 'utf8' });
  assert.equal(outputFailure.status, 1);
  assert.equal(outputFailure.stderr.includes(fixtures), false);
  assert.deepEqual(fs.readFileSync(path.join(directoryOutput, 'preserved')), before);
  const messages = [
    'safe prefix: /outside/synthetic path/file.js',
    'safe prefix: "C:\\synthetic directory\\file.js"; safe context',
    'safe prefix: \\synthetic\\file.js',
    'safe prefix: \\\\server\\share\\file.js',
    'safe prefix: first line\n/opt/synthetic/file.js\nD:/synthetic/file.js',
    'safe prefix: "/outside/synthetic\nmultiline path/file.js"; safe context',
    'safe prefix: relative/file.js'
  ];
  for (const boundary of ['read', 'output', 'vm']) for (const message of messages) {
    const result = spawnSync(process.execPath, ['-e', `
      const fs = require('fs'), vm = require('vm');
      const originalRead = fs.readFileSync, originalOpen = fs.openSync;
      const fail = () => { const e = new Error(process.env.SYNTHETIC_DIAGNOSTIC); e.stack += '\\n at /outside/stack.js'; throw e; };
      if (process.env.BOUNDARY === 'read') fs.readFileSync = (...args) =>
        args[0] === process.env.RAW_INPUT ? fail() : originalRead(...args);
      if (process.env.BOUNDARY === 'output') fs.openSync = (...args) =>
        String(args[0]).endsWith('.document-language.tmp') ? fail() : originalOpen(...args);
      if (process.env.BOUNDARY === 'vm') vm.runInNewContext = fail;
      process.argv = [process.execPath, process.env.ENHANCER_ENTRY, '--input', process.env.RAW_INPUT, '--output', process.env.FINAL_OUTPUT];
      require(process.env.ENHANCER_ENTRY);
    `], { encoding: 'utf8', env: { ...process.env, ENHANCER_ENTRY: enhance, RAW_INPUT: rawCanvas,
      FINAL_OUTPUT: output, SYNTHETIC_DIAGNOSTIC: message, BOUNDARY: boundary } });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
    assert.match(result.stderr, /document-language enhancement failed:/);
    assert.equal(/\/outside|\/opt|[CD]:[\\/]|\\synthetic|\\server/.test(result.stderr), false, boundary + ': ' + result.stderr);
    if (message.includes('relative/file.js')) assert.match(result.stderr, /relative\/file\.js/);
    assert.deepEqual(fs.readFileSync(output), before);
  }
});
test('unsafe delivery stdout metadata fails closed and preserves the previous receipt bytes', async () => {
  const previous = fs.readFileSync(path.join(fixtures, 'valid.delivery.json'));
  const actualSpawn = childProcess.spawnSync;
  const previousCwd = process.cwd();
  let injected = false;
  let mutation;
  childProcess.spawnSync = (...args) => {
    const result = actualSpawn(...args);
    if (args[1]?.[0]?.endsWith('/bin/archify.mjs') && args[1][1] === 'deliver' && result.status === 0) {
      // Simulate untrusted producer stdout only in this private test fixture.
      const capture = fs.readdirSync(fixtures).find(name => name.startsWith('.archify-receipt-'));
      const raw = JSON.parse(fs.readFileSync(path.join(fixtures, capture)));
      mutation(raw);
      fs.ftruncateSync(args[2].stdio[1], 0);
      fs.writeSync(args[2].stdio[1], Buffer.from(JSON.stringify(raw)), 0, undefined, 0);
      injected = true;
    }
    return result;
  };
  syncBuiltinESMExports();
  process.chdir(fixtures);
  try {
    for (const [change, failure] of [
      [raw => { raw.provenance = { nested: [{ arbitrary: 'cwd:/outside/synthetic' }] }; }, /relative/],
      [raw => { raw.provenance = { nested: [{ arbitrary: 'cwd:../outside' }] }; }, /relative/],
      [raw => { raw.commandMetadata = { command: 'node tool.mjs --arg=`root:..\\outside`' }; }, /relative/],
      [raw => { raw.schemaVersion = 999; }, /schema/],
      [raw => { raw.type = 'lifecycle'; }, /type/]
    ]) {
      mutation = change;
      injected = false;
      await assert.rejects(run(['deliver', 'sequence', 'valid.json', 'valid.html',
        '--repo-root', '.', '--quality', 'showcase', '--json']), failure);
      assert.equal(injected, true);
      assert.deepEqual(fs.readFileSync('valid.delivery.json'), previous);
      assert.equal(fs.readdirSync('.').some(name => name.startsWith('.archify-')), false);
      // HTML may already have committed upstream; this is not a two-file transaction.
      assert.equal(fs.existsSync('valid.html'), true);
    }
  } finally {
    process.chdir(previousCwd);
    childProcess.spawnSync = actualSpawn;
    syncBuiltinESMExports();
  }
});
