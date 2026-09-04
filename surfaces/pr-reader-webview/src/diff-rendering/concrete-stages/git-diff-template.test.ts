// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffFileStatus } from "../contracts/diff-view-model";
import {
  createGitDiffTemplate,
  createGitDiffTemplateInput,
} from "./git-diff-template";

const patch = "@@ -1 +1 @@\n-old\n+new";

describe("GitDiffTemplate", () => {
  test.each([
    [
      "added",
      "src/added.ts",
      undefined,
      ["--- /dev/null", "+++ b/src/added.ts"],
    ],
    [
      "removed",
      "src/removed.ts",
      undefined,
      ["--- a/src/removed.ts", "+++ /dev/null"],
    ],
    [
      "modified",
      "src/modified.ts",
      undefined,
      ["--- a/src/modified.ts", "+++ b/src/modified.ts"],
    ],
    [
      "renamed",
      "src/renamed.ts",
      "src/previous.ts",
      [
        "rename from src/previous.ts",
        "rename to src/renamed.ts",
        "--- a/src/previous.ts",
        "+++ b/src/renamed.ts",
      ],
    ],
  ])(
    "creates a parseable unified diff for %s files",
    (status: DiffFileStatus, filename: string, previousFilename:
      | string
      | undefined, expectedLines: readonly string[]) => {
      const input = createGitDiffTemplateInput({
        fileId: "file-1",
        filename,
        previousFilename,
        status,
        patch,
      });

      const source = createGitDiffTemplate(input).toUnifiedDiff();

      expect(Object.isFrozen(input)).toBe(true);
      expect(source).toContain(
        `diff --git a/${previousFilename ?? filename} b/${filename}`,
      );
      for (const expectedLine of expectedLines) {
        expect(source).toContain(expectedLine);
      }
      expect(source).not.toContain("index ");
      expect(source).not.toContain("100644");
      expect(source).toEndWith(patch);
    },
  );

  test("serializes every non-null path with Git C-style quoting and side prefixes", () => {
    const filename = 'src/new name"\\\n\u0007\u007f\u00e9.ts';
    const previousFilename = "src/old name\t\u00e9.ts";
    const source = createGitDiffTemplate(
      createGitDiffTemplateInput({
        fileId: "file-1",
        filename,
        previousFilename,
        status: "renamed",
        patch,
      }),
    ).toUnifiedDiff();

    expect(source).toContain(
      'diff --git "a/src/old name\\t\\303\\251.ts" "b/src/new name\\"\\\\\\n\\a\\177\\303\\251.ts"',
    );
    expect(source).toContain('rename from "src/old name\\t\\303\\251.ts"');
    expect(source).toContain(
      'rename to "src/new name\\"\\\\\\n\\a\\177\\303\\251.ts"',
    );
    expect(source).toContain('--- "a/src/old name\\t\\303\\251.ts"');
    expect(source).toContain(
      '+++ "b/src/new name\\"\\\\\\n\\a\\177\\303\\251.ts"',
    );
  });
});
