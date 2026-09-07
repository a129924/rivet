// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { DiffFile } from "diff2html/lib/types";
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

function validatedSingleFileSnapshot() {
  const validationResult = createDiffViewModelValidator().validate({
    ...snapshot,
    files: [snapshot.files[0]],
  });
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

  test("converts an incomplete third-party hunk result to a stable parse-error", () => {
    const result = createDiffParser({
      parseDiff() {
        return [
          {
            isGitDiff: true,
            blocks: [
              {
                header: "@@ -1,2 +1,2 @@",
                lines: [
                  {
                    content: "-old",
                    type: "delete",
                    oldNumber: 1,
                    newNumber: undefined,
                  },
                  {
                    content: "+new",
                    type: "insert",
                    oldNumber: undefined,
                    newNumber: 1,
                  },
                ],
              },
            ],
          },
        ] as unknown as DiffFile[];
      },
    }).parse(validatedSingleFileSnapshot());

    expect(result).toEqual({
      type: "error",
      kind: "parse-error",
      message: "Diff parsing failed.",
    });
  });

  test("converts an unparseable third-party hunk header to a stable parse-error", () => {
    const result = createDiffParser({
      parseDiff() {
        return [
          {
            isGitDiff: true,
            blocks: [{ header: "unparseable", lines: [] }],
          },
        ] as unknown as DiffFile[];
      },
    }).parse(validatedSingleFileSnapshot());

    expect(result).toEqual({
      type: "error",
      kind: "parse-error",
      message: "Diff parsing failed.",
    });
  });

  test("accepts equivalent source and parsed hunk tuples despite count shorthand", () => {
    const result = createDiffParser({
      parseDiff(source) {
        expect(source).toContain("diff --git a/src/added.ts b/src/added.ts");
        return [
          {
            isGitDiff: true,
            blocks: [
              {
                header: "@@ -1,1 +1,1 @@",
                lines: [
                  {
                    content: "-old",
                    type: "delete",
                    oldNumber: 1,
                    newNumber: undefined,
                  },
                  {
                    content: "+new",
                    type: "insert",
                    oldNumber: undefined,
                    newNumber: 1,
                  },
                ],
              },
            ],
          },
        ] as unknown as DiffFile[];
      },
    }).parse(validatedSingleFileSnapshot());

    expect(result.type).toBe("success");
  });

  test("converts a silently truncated multi-hunk parse result to a stable parse-error", () => {
    const multiHunkPatch =
      "@@ -1 +1 @@\n-old\n+new\n@@ -4 +4 @@\n-old-two\n+new-two";
    const validationResult = createDiffViewModelValidator().validate({
      ...snapshot,
      files: [{ ...snapshot.files[0], patch: multiHunkPatch }],
    });
    if (validationResult.type === "error") {
      throw new Error(validationResult.message);
    }

    const result = createDiffParser({
      parseDiff() {
        return [
          {
            isGitDiff: true,
            blocks: [
              {
                header: "@@ -1 +1 @@",
                lines: [
                  {
                    content: "-old",
                    type: "delete",
                    oldNumber: 1,
                    newNumber: undefined,
                  },
                  {
                    content: "+new",
                    type: "insert",
                    oldNumber: undefined,
                    newNumber: 1,
                  },
                ],
              },
            ],
          },
        ] as unknown as DiffFile[];
      },
    }).parse(validationResult.value);

    expect(result).toEqual({
      type: "error",
      kind: "parse-error",
      message: "Diff parsing failed.",
    });
    if (result.type === "success") {
      throw new Error("Expected parsing to fail.");
    }
    expect(result.message).not.toContain(multiHunkPatch);
  });

  test("converts mismatched third-party line content to a stable parse-error", () => {
    const result = createDiffParser({
      parseDiff() {
        return parsedSingleHunkDiff([
          parsedLine(" changed", "context", 1, 1),
          parsedLine("-old", "delete", 2, undefined),
          parsedLine("+new", "insert", undefined, 2),
        ]);
      },
    }).parse(validatedTrailingLineFeedSnapshot());

    expect(result).toEqual(parseError());
  });

  test("converts mismatched third-party line types to a stable parse-error", () => {
    const result = createDiffParser({
      parseDiff() {
        return parsedSingleHunkDiff([
          parsedLine(" ", "delete", 1, undefined),
          parsedLine("-old", "context", 2, 2),
          parsedLine("+new", "insert", undefined, 2),
        ]);
      },
    }).parse(validatedTrailingLineFeedSnapshot());

    expect(result).toEqual(parseError());
  });

  test("converts mismatched third-party line numbers to a stable parse-error", () => {
    const result = createDiffParser({
      parseDiff() {
        return parsedSingleHunkDiff([
          parsedLine(" ", "context", 2, 1),
          parsedLine("-old", "delete", 1, undefined),
          parsedLine("+new", "insert", undefined, 2),
        ]);
      },
    }).parse(validatedTrailingLineFeedSnapshot());

    expect(result).toEqual(parseError());
  });

  test("converts an unknown source hunk line prefix to a stable parse-error", () => {
    const unknownPrefixPatch = "@@ -1 +1 @@\n!unexpected";
    const validationResult = createDiffViewModelValidator().validate({
      ...snapshot,
      files: [{ ...snapshot.files[0], patch: unknownPrefixPatch }],
    });
    if (validationResult.type === "error") {
      throw new Error(validationResult.message);
    }

    const result = createDiffParser().parse(validationResult.value);

    expect(result).toEqual(parseError());
    if (result.type === "success") {
      throw new Error("Expected parsing to fail.");
    }
    expect(result.message).not.toContain(unknownPrefixPatch);
  });

  test("accepts a real trailing-LF blank context, delete, and insert hunk", () => {
    const result = createDiffParser().parse(
      validatedTrailingLineFeedSnapshot(),
    );

    expect(result.type).toBe("success");
  });
});

const trailingLineFeedPatch = "@@ -1,2 +1,2 @@\n \n-old\n+new\n";

function validatedTrailingLineFeedSnapshot() {
  const validationResult = createDiffViewModelValidator().validate({
    ...snapshot,
    files: [{ ...snapshot.files[0], patch: trailingLineFeedPatch }],
  });
  if (validationResult.type === "error") {
    throw new Error(validationResult.message);
  }
  return validationResult.value;
}

function parsedSingleHunkDiff(lines: readonly unknown[]): DiffFile[] {
  return [
    {
      isGitDiff: true,
      blocks: [
        {
          header: "@@ -1,2 +1,2 @@",
          lines,
        },
      ],
    },
  ] as unknown as DiffFile[];
}

function parsedLine(
  content: string,
  type: "context" | "delete" | "insert",
  oldNumber: number | undefined,
  newNumber: number | undefined,
) {
  return { content, type, oldNumber, newNumber };
}

function parseError() {
  return {
    type: "error" as const,
    kind: "parse-error" as const,
    message: "Diff parsing failed.",
  };
}
