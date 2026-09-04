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
      ["new file mode 100644", "--- /dev/null", "+++ b/src/added.ts"],
    ],
    [
      "removed",
      "src/removed.ts",
      undefined,
      ["deleted file mode 100644", "--- a/src/removed.ts", "+++ /dev/null"],
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
      expect(source).toEndWith(patch);
    },
  );
});
