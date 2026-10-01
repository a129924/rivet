import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createHash, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const producer = path.dirname(fileURLToPath(import.meta.url));
const patchTargets = ['schemas/sequence.schema.json', 'schemas/lifecycle.schema.json',
  'renderers/shared/generated-validators.mjs', 'renderers/shared/cli.mjs', 'renderers/shared/utils.mjs'];
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const inside = (root, target) => {
  const relative = path.relative(root, target);
  return relative === '' || (!path.isAbsolute(relative) && relative !== '..' && !relative.startsWith('../'));
};
export function canonicalFuture(target) {
  let ancestor = path.resolve(target);
  const missing = [];
  while (!fs.existsSync(ancestor)) {
    // A dangling symlink must fail rather than be treated as a new regular file.
    try { if (fs.lstatSync(ancestor).isSymbolicLink()) throw new Error('Dangling output symlink refused.'); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    missing.unshift(path.basename(ancestor));
    const parent = path.dirname(ancestor);
    if (parent === ancestor) throw new Error('Output ancestor unavailable.');
    ancestor = parent;
  }
  return path.join(fs.realpathSync(ancestor), ...missing);
}
export function contained(root, relative, mustExist = false) {
  if (typeof relative !== 'string' || !relative || path.isAbsolute(relative) ||
    relative.split(/[\\/]/).includes('..')) throw new Error('Use repository-relative paths without parent traversal.');
  const target = path.resolve(root, relative);
  const canonical = mustExist ? fs.realpathSync(target) : canonicalFuture(target);
  if (!inside(root, canonical)) throw new Error('Canonical path escapes repository root.');
  return canonical;
}
export function verifyPins(upstream, manifest) {
  if (manifest.schemaVersion !== 1 || !manifest.files || !Object.keys(manifest.files).length)
    throw new Error('Incomplete upstream manifest.');
  for (const [relative, expected] of Object.entries(manifest.files)) {
    const target = contained(upstream, relative, true);
    if (!fs.lstatSync(path.join(upstream, relative)).isFile() ||
      !/^[0-9a-f]{64}$/.test(expected) || sha256(fs.readFileSync(target)) !== expected)
      throw new Error('Upstream pin mismatch: ' + relative);
  }
}
export function prepareRuntime(upstream, manifest = JSON.parse(fs.readFileSync(path.join(producer, 'upstream-pin.json')))) {
  upstream = fs.realpathSync(upstream);
  verifyPins(upstream, manifest); // All pins before copy, patch, artifact, or receipt writing.
  const runtime = fs.mkdtempSync(path.join(os.tmpdir(), 'rivet-archify-runtime-'));
  try {
    for (const relative of Object.keys(manifest.files)) {
      const destination = path.join(runtime, relative);
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      fs.copyFileSync(path.join(upstream, relative), destination);
      if (sha256(fs.readFileSync(destination)) !== manifest.files[relative])
        throw new Error('Copied upstream pin mismatch: ' + relative);
    }
    const patch = fs.readFileSync(path.join(producer, 'document-language.patch'), 'utf8');
    const targets = [...patch.matchAll(/^\+\+\+ b\/(.+)$/gm)].map(match => match[1]);
    if (JSON.stringify(targets) !== JSON.stringify(patchTargets)) throw new Error('Overlay patch target mismatch.');
    const applied = spawnSync('patch', ['-p1', '--batch', '--forward'], { cwd: runtime, input: patch, encoding: 'utf8' });
    if (applied.status !== 0) throw new Error('Pinned overlay patch failed.');
    const checked = spawnSync(process.execPath, ['scripts/generate-validators.mjs', '--check'],
      { cwd: runtime, encoding: 'utf8' });
    if (checked.status !== 0) throw new Error('Generated validators differ from the pinned generator.');
    return runtime;
  } catch (error) { fs.rmSync(runtime, { recursive: true, force: true }); throw error; }
}
export function verifyReceipt(bytes, root, input, output) {
  const receipt = JSON.parse(bytes.toString('utf8'));
  if (!receipt.ok || receipt.command !== 'deliver' || receipt.input !== input || receipt.output !== output)
    throw new Error('Delivery receipt identity mismatch.');
  const validation = receipt.validation;
  if (validation?.checksPassed !== 9 || validation?.checkCount !== 9 ||
    validation?.compositionProfile !== 'showcase' || validation?.errors !== 0 || validation?.warnings !== 0)
    throw new Error('Delivery requires showcase 9/9 with zero errors and warnings.');
  for (const [key, relative] of [['specification', input], ['artifact', output]]) {
    const actual = fs.readFileSync(contained(root, relative, true));
    if (receipt[key]?.sha256 !== sha256(actual) || receipt[key]?.bytes !== actual.length)
      throw new Error('Delivery receipt bytes/hash mismatch: ' + key);
  }
  const checkPaths = value => {
    if (typeof value === 'string') {
      // Inspect every string, independent of field names. Command strings also
      // carry paths as quote/backtick-framed arguments or option=value tokens.
      const tokens = value.split(/[\s"'`=,;()[\]{}]+/);
      if (tokens.some(token => /^[\\/]/.test(token) || /^[a-zA-Z]:/.test(token) ||
        token.split(/[\\/]/).includes('..')))
        throw new Error('Receipt metadata path is not repository-relative.');
    } else if (Array.isArray(value)) value.forEach(checkPaths);
    else if (value && typeof value === 'object') {
      for (const [key, nested] of Object.entries(value)) {
        checkPaths(key);
        checkPaths(nested);
      }
    }
  };
  checkPaths(receipt);
  return receipt;
}
export async function run(args, options = {}) {
  const rootIndex = args.indexOf('--repo-root');
  const rootRequest = rootIndex < 0 ? '.' : args[rootIndex + 1];
  if (!rootRequest) throw new Error('--repo-root requires a root.');
  const rest = rootIndex < 0 ? [...args] : args.filter((_, i) => i !== rootIndex && i !== rootIndex + 1);
  if (rest.some(arg => arg === '--repo-root' || arg.startsWith('--repo-root=')))
    throw new Error('Only one explicit --repo-root argument is allowed.');
  const root = fs.realpathSync(path.resolve(rootRequest));
  if (fs.realpathSync(process.cwd()) !== root) throw new Error('Run from the canonical repository root.');
  const [command, typeOrInput, inputOrOutput, requestedOutput] = rest;
  const positionalCount = command === 'visual-check' ? 2 : command === 'deliver' ? 4 : 3;
  for (let i = positionalCount; i < rest.length; i++) {
    if (rest[i] === '--json') continue;
    if (rest[i] === '--quality' && rest[i + 1] === 'showcase') { i++; continue; }
    throw new Error('Only --json and --quality showcase options are supported.');
  }
  if (!['validate', 'deliver', 'visual-check'].includes(command)) throw new Error('Only validate, deliver, visual-check are supported.');
  const input = command === 'visual-check' ? typeOrInput : inputOrOutput;
  const output = command === 'deliver' ? requestedOutput : undefined;
  const inputPath = contained(root, input, true);
  if (output) contained(root, output);
  if (command === 'deliver' && !output) throw new Error('Delivery requires explicit repository-relative output.');
  if (command !== 'visual-check' && !['sequence', 'lifecycle'].includes(typeOrInput))
    throw new Error('Only sequence/lifecycle overlays are supported.');
  if (command !== 'visual-check' && !rest.includes('--quality')) rest.push('--quality', 'showcase');
  const manifest = options.manifest || JSON.parse(fs.readFileSync(path.join(producer, 'upstream-pin.json')));
  const upstream = options.upstream || process.env.ARCHIFY_UPSTREAM_ROOT ||
    path.join(os.homedir(), '.codex', 'skills', 'archify');
  const runtime = prepareRuntime(upstream, manifest);
  let capture;
  try {
    if (command !== 'visual-check') {
      const diagram = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
      const { validateSchema } = await import(pathToFileURL(path.join(runtime, 'renderers/shared/validator.mjs')));
      validateSchema(typeOrInput, diagram); // Invalid language fails before any output/capture file.
      if (diagram.meta?.output) contained(root, diagram.meta.output);
    }
    if (!rest.includes('--json')) rest.push('--json');
    const cliArgs = [...rest, '--repo-root', '.'];
    if (command !== 'deliver') {
      const result = spawnSync(process.execPath, [path.join(runtime, 'bin/archify.mjs'), ...cliArgs],
        { cwd: root, env: { ...process.env, ARCHIFY_REPO_ROOT: root }, stdio: 'inherit' });
      return result.status ?? 1;
    }
    const receiptRelative = output.replace(/\.html$/, '.delivery.json');
    if (receiptRelative === output) throw new Error('Delivery output must end in .html.');
    const receiptPath = contained(root, receiptRelative);
    if (receiptPath === inputPath) throw new Error('Receipt must not overwrite source.');
    fs.mkdirSync(path.dirname(receiptPath), { recursive: true });
    const raw = path.join(path.dirname(receiptPath), '.archify-receipt-' + randomUUID() + '.json');
    capture = raw;
    const fd = fs.openSync(raw, 'wx');
    let result;
    try {
      result = spawnSync(process.execPath, [path.join(runtime, 'bin/archify.mjs'), ...cliArgs],
        { cwd: root, env: { ...process.env, ARCHIFY_REPO_ROOT: root }, stdio: ['ignore', fd, 'inherit'] });
    } finally { fs.closeSync(fd); }
    if (result.status !== 0) {
      process.stdout.write(fs.readFileSync(raw));
      return result.status ?? 1;
    }
    const bytes = fs.readFileSync(raw);
    verifyReceipt(bytes, root, input, output);
    if (contained(root, receiptRelative) !== receiptPath) throw new Error('Receipt alias changed before commit.');
    fs.renameSync(raw, receiptPath); // Original stdout bytes, same-directory filesystem atomic rename.
    process.stdout.write(bytes);
    return 0;
  } finally {
    if (capture && fs.existsSync(capture)) fs.unlinkSync(capture);
    fs.rmSync(runtime, { recursive: true, force: true });
  }
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { process.exitCode = await run(process.argv.slice(2)); }
  catch (error) {
    // Safe bounded diagnostics; never persist tool installation/runtime paths.
    const message = error.archifyDiagnostics ? 'Source schema validation failed.' :
      String(error.message).replace(/(?:\/Users\/|\/home\/|\/private\/|\/var\/)[^\s"']+/g, '[local path]');
    console.error(message);
    process.exitCode = 1;
  }
}
