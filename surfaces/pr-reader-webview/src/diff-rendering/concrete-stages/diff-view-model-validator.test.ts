// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import { createDiffViewModelValidator } from "./diff-view-model-validator";

const validSnapshot: DiffSnapshot = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  files: [
    {
      fileId: "file-1",
      filename: "src/example.ts",
      status: "modified",
      patch: "@@ -1 +1 @@\n-old\n+new",
      additions: 1,
      deletions: 1,
      viewed: false,
    },
  ],
};

describe("createDiffViewModelValidator", () => {
  test("creates a validated opaque input for a structurally valid snapshot", () => {
    const result = createDiffViewModelValidator().validate(validSnapshot);

    expect(result.type).toBe("success");
  });

  test.each([
    ["non-object snapshot", "not a snapshot"],
    ["empty snapshot identity", { ...validSnapshot, snapshotId: "" }],
    ["non-object file entry", { ...validSnapshot, files: ["not a file"] }],
    [
      "duplicate file identity",
      {
        ...validSnapshot,
        files: [...validSnapshot.files, { ...validSnapshot.files[0] }],
      },
    ],
    [
      "invalid status",
      {
        ...validSnapshot,
        files: [{ ...validSnapshot.files[0], status: "copied" }],
      },
    ],
    [
      "renamed file without previous filename",
      {
        ...validSnapshot,
        files: [
          { ...validSnapshot.files[0], status: "renamed", patch: undefined },
        ],
      },
    ],
    [
      "previous filename for a non-renamed file",
      {
        ...validSnapshot,
        files: [
          {
            ...validSnapshot.files[0],
            previousFilename: "src/previous.ts",
          },
        ],
      },
    ],
    [
      "non-boolean viewed state",
      {
        ...validSnapshot,
        files: [{ ...validSnapshot.files[0], viewed: "yes" }],
      },
    ],
    [
      "unsafe counter",
      {
        ...validSnapshot,
        files: [
          { ...validSnapshot.files[0], additions: Number.MAX_SAFE_INTEGER + 1 },
        ],
      },
    ],
    [
      "negative additions counter",
      {
        ...validSnapshot,
        files: [{ ...validSnapshot.files[0], additions: -1 }],
      },
    ],
    [
      "negative deletions counter",
      {
        ...validSnapshot,
        files: [{ ...validSnapshot.files[0], deletions: -1 }],
      },
    ],
    [
      "whitespace-only file identity",
      {
        ...validSnapshot,
        files: [{ ...validSnapshot.files[0], fileId: " \t" }],
      },
    ],
    [
      "whitespace-only filename",
      {
        ...validSnapshot,
        files: [{ ...validSnapshot.files[0], filename: "\n" }],
      },
    ],
    [
      "non-string patch",
      { ...validSnapshot, files: [{ ...validSnapshot.files[0], patch: 42 }] },
    ],
  ])(
    "returns a stable invalid-input error for %s",
    (_caseName: string, invalidSnapshot: unknown) => {
      const result = createDiffViewModelValidator().validate(
        invalidSnapshot as DiffSnapshot,
      );

      expect(result).toEqual({
        type: "error",
        kind: "invalid-input",
        message: "Diff snapshot validation failed.",
      });
      if (result.type === "success") {
        throw new Error("Expected invalid input to fail validation.");
      }
      expect(result.message).not.toContain("old");
    },
  );
});
