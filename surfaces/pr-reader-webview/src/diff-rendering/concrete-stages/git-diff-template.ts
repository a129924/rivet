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
  const header = `diff --git a/${previousFilename} b/${input.filename}`;
  const patchLines = input.patch;

  switch (input.status) {
    case "added":
      return [
        header,
        "new file mode 100644",
        "--- /dev/null",
        `+++ b/${input.filename}`,
        patchLines,
      ].join("\n");
    case "removed":
      return [
        header,
        "deleted file mode 100644",
        `--- a/${input.filename}`,
        "+++ /dev/null",
        patchLines,
      ].join("\n");
    case "modified":
      return [
        header,
        `--- a/${input.filename}`,
        `+++ b/${input.filename}`,
        patchLines,
      ].join("\n");
    case "renamed":
      return [
        header,
        `rename from ${previousFilename}`,
        `rename to ${input.filename}`,
        `--- a/${previousFilename}`,
        `+++ b/${input.filename}`,
        patchLines,
      ].join("\n");
  }
}
