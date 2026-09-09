import type { DiffFileStatus } from "../contracts/diff-view-model";

export interface GitDiffTemplateInput {
  readonly fileId: string;
  readonly filename: string;
  readonly previousFilename?: string;
  readonly status: DiffFileStatus;
  readonly patch: string;
}

export interface GitDiffTemplate {
  toUnifiedDiff(): string;
}

export function createGitDiffTemplateInput(
  input: GitDiffTemplateInput,
): GitDiffTemplateInput {
  return Object.freeze({ ...input });
}

export function createGitDiffTemplate(
  input: GitDiffTemplateInput,
): GitDiffTemplate {
  const source = createUnifiedDiff(input);
  return Object.freeze({
    toUnifiedDiff() {
      return source;
    },
  });
}

function createUnifiedDiff(input: GitDiffTemplateInput): string {
  const previousFilename = input.previousFilename ?? input.filename;
  const oldPath = serializeGitPath(`a/${previousFilename}`);
  const newPath = serializeGitPath(`b/${input.filename}`);
  const header = `diff --git ${oldPath} ${newPath}`;
  const patchLines = input.patch;

  switch (input.status) {
    case "added":
      return [header, "--- /dev/null", `+++ ${newPath}`, patchLines].join("\n");
    case "removed":
      return [header, `--- ${oldPath}`, "+++ /dev/null", patchLines].join("\n");
    case "modified":
      return [header, `--- ${oldPath}`, `+++ ${newPath}`, patchLines].join(
        "\n",
      );
    case "renamed":
      return [
        header,
        `rename from ${serializeGitPath(previousFilename)}`,
        `rename to ${serializeGitPath(input.filename)}`,
        `--- ${oldPath}`,
        `+++ ${newPath}`,
        patchLines,
      ].join("\n");
  }
}

function serializeGitPath(path: string): string {
  if (/^[A-Za-z0-9._/+-]+$/.test(path)) {
    return path;
  }

  let escapedPath = "";
  for (const character of path) {
    escapedPath += escapeGitPathCharacter(character);
  }
  return `"${escapedPath}"`;
}

function escapeGitPathCharacter(character: string): string {
  switch (character) {
    case '"':
      return '\\"';
    case "\\":
      return "\\\\";
    case "\u0007":
      return "\\a";
    case "\b":
      return "\\b";
    case "\f":
      return "\\f";
    case "\n":
      return "\\n";
    case "\r":
      return "\\r";
    case "\t":
      return "\\t";
    case "\v":
      return "\\v";
  }

  const codePoint = character.codePointAt(0);
  if (codePoint !== undefined && (codePoint < 0x20 || codePoint === 0x7f)) {
    return `\\${codePoint.toString(8).padStart(3, "0")}`;
  }
  if (codePoint !== undefined && codePoint < 0x80) {
    return character;
  }

  return [...new TextEncoder().encode(character)]
    .map((byte) => `\\${byte.toString(8).padStart(3, "0")}`)
    .join("");
}
