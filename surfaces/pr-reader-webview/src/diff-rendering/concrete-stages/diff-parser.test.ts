// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import { createDiffViewModelValidator } from "./diff-view-model-validator";
import { createDiffParser, readParsedDiffInput } from "./diff-parser";

const patch = "@@ -1 +1 @@\n-old\n+new";

const snapshot: DiffSnapshot = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  files: [
    {
      fileId: "added",
      filename: "src/added.ts",
      status: "added",
      patch,
      additions: 1,
      deletions: 0,
      viewed: false,
    },
    {
      fileId: "removed",
      filename: "src/removed.ts",
      status: "removed",
      patch,
      additions: 0,
      deletions: 1,
      viewed: false,
    },
    {
      fileId: "modified",
      filename: "src/modified.ts",
      status: "modified",
      patch,
      additions: 1,
      deletions: 1,
      viewed: true,
    },
    {
      fileId: "renamed",
      filename: "src/renamed.ts",
      previousFilename: "src/previous.ts",
      status: "renamed",
      patch,
      additions: 1,
      deletions: 1,
      viewed: false,
    },
    {
      fileId: "metadata-only",
      filename: "src/metadata.ts",
      status: "modified",
      additions: 0,
      deletions: 0,
      viewed: false,
    },
  ],
};

function validatedSnapshot() {
  const validationResult = createDiffViewModelValidator().validate(snapshot);
  if (validationResult.type === "error") {
    throw new Error(validationResult.message);
  }
  return validationResult.value;
}

describe("createDiffParser", () => {
  test("parses each patch in snapshot order and retains no-patch metadata", () => {
    const result = createDiffParser().parse(validatedSnapshot());

    expect(result.type).toBe("success");
    if (result.type === "error") {
      throw new Error(result.message);
    }

    const entries = readParsedDiffInput(result.value).entries;
    expect(
      entries.map((entry) => ({ kind: entry.kind, fileId: entry.file.fileId })),
    ).toEqual([
      { kind: "parsed", fileId: "added" },
      { kind: "parsed", fileId: "removed" },
      { kind: "parsed", fileId: "modified" },
      { kind: "parsed", fileId: "renamed" },
      { kind: "metadata-unavailable", fileId: "metadata-only" },
    ]);
    for (const entry of entries.slice(0, 4)) {
      if (entry.kind === "parsed") {
        expect(entry.diff).not.toHaveLength(0);
      }
    }
  });

  test("converts dependency exceptions to a stable parse-error without patch content", () => {
    const result = createDiffParser({
      parseDiff() {
        throw new Error(`dependency failure: ${patch}`);
      },
    }).parse(validatedSnapshot());

    expect(result).toEqual({
      type: "error",
      kind: "parse-error",
      message: "Diff parsing failed.",
    });
    if (result.type === "success") {
      throw new Error("Expected parsing to fail.");
    }
    expect(result.message).not.toContain(patch);
  });

  test("converts a malformed unified-diff patch to a stable parse-error", () => {
    const malformedPatch = "@@ malformed hunk @@\n-old\n+new";
    const validationResult = createDiffViewModelValidator().validate({
      ...snapshot,
      files: [{ ...snapshot.files[0], patch: malformedPatch }],
    });
    if (validationResult.type === "error") {
      throw new Error(validationResult.message);
    }

    const result = createDiffParser().parse(validationResult.value);

    expect(result).toEqual({
      type: "error",
      kind: "parse-error",
      message: "Diff parsing failed.",
    });
    if (result.type === "success") {
      throw new Error("Expected malformed patch parsing to fail.");
    }
    expect(result.message).not.toContain(malformedPatch);
  });
});
