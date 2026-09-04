// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import { createDiffParser } from "./diff-parser";
import { createDiffRenderer, readRenderPlan } from "./diff-renderer";
import { createDiffViewModelValidator } from "./diff-view-model-validator";

const snapshot: DiffSnapshot = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  files: [
    {
      fileId: "rendered",
      filename: "src/rendered.ts",
      status: "modified",
      patch: "@@ -1 +1 @@\n-old\n+new",
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
      viewed: true,
    },
  ],
};

function parsedSnapshot() {
  const validationResult = createDiffViewModelValidator().validate(snapshot);
  if (validationResult.type === "error") {
    throw new Error(validationResult.message);
  }
  const parseResult = createDiffParser().parse(validationResult.value);
  if (parseResult.type === "error") {
    throw new Error(parseResult.message);
  }
  return parseResult.value;
}

describe("createDiffRenderer", () => {
  test("creates rendered and metadata entries in original order", () => {
    const result = createDiffRenderer().createRenderPlan(parsedSnapshot());

    expect(result.type).toBe("success");
    if (result.type === "error") {
      throw new Error(result.message);
    }

    const entries = readRenderPlan(result.value).entries;
    expect(
      entries.map((entry) => ({ kind: entry.kind, fileId: entry.file.fileId })),
    ).toEqual([
      { kind: "rendered", fileId: "rendered" },
      { kind: "metadata-unavailable", fileId: "metadata-only" },
    ]);
    if (entries[0]?.kind !== "rendered") {
      throw new Error("Expected the patched file to be rendered.");
    }
    expect(entries[0].html).toContain("d2h-file-wrapper");
  });

  test("uses line-by-line rendering without a file list", () => {
    let receivedConfiguration: unknown;
    const result = createDiffRenderer({
      renderDiff(_diff, configuration) {
        receivedConfiguration = configuration;
        return "<section>rendered</section>";
      },
    }).createRenderPlan(parsedSnapshot());

    expect(result.type).toBe("success");
    expect(receivedConfiguration).toEqual({
      outputFormat: "line-by-line",
      drawFileList: false,
    });
  });

  test("converts dependency exceptions to a stable render-error without patch content", () => {
    const result = createDiffRenderer({
      renderDiff() {
        throw new Error("dependency failure: old");
      },
    }).createRenderPlan(parsedSnapshot());

    expect(result).toEqual({
      type: "error",
      kind: "render-error",
      message: "Diff rendering failed.",
    });
    if (result.type === "success") {
      throw new Error("Expected rendering to fail.");
    }
    expect(result.message).not.toContain("old");
  });
});
