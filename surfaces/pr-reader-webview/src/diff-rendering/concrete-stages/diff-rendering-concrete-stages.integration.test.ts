// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { RenderPlan } from "../contracts/opaque-stage-inputs";
import type { DiffOutputPort } from "../ports/diff-output-port";
import { createDiffRenderUseCase } from "../usecases/diff-render-use-case";
import { createDiffParser } from "./diff-parser";
import { createDiffRenderer, readRenderPlan } from "./diff-renderer";
import { createDiffViewModelValidator } from "./diff-view-model-validator";

const validSnapshot: DiffSnapshot = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  files: [
    {
      fileId: "patched-file",
      filename: "src/example.ts",
      status: "modified",
      patch: "@@ -1 +1 @@\n-old\n+new",
      additions: 1,
      deletions: 1,
      viewed: false,
    },
    {
      fileId: "metadata-only-file",
      filename: "src/metadata.ts",
      status: "modified",
      additions: 0,
      deletions: 0,
      viewed: true,
    },
  ],
};

function createOutputTestDouble() {
  const receivedPlans: RenderPlan[] = [];
  const output: DiffOutputPort = {
    output(plan) {
      receivedPlans.push(plan);
      return { type: "success" };
    },
  };
  return { output, receivedPlans };
}

describe("concrete diff rendering stages", () => {
  test("parses and renders every patch status without Git blob index metadata", () => {
    const statusSnapshot: DiffSnapshot = {
      ...validSnapshot,
      files: [
        {
          fileId: "added",
          filename: "src/added.ts",
          status: "added",
          patch: "@@ -0,0 +1 @@\n+new",
          additions: 1,
          deletions: 0,
          viewed: false,
        },
        {
          fileId: "removed",
          filename: "src/removed.ts",
          status: "removed",
          patch: "@@ -1 +0,0 @@\n-old",
          additions: 0,
          deletions: 1,
          viewed: false,
        },
        {
          fileId: "modified",
          filename: "src/modified.ts",
          status: "modified",
          patch: "@@ -1 +1 @@\n-old\n+new",
          additions: 1,
          deletions: 1,
          viewed: false,
        },
        {
          fileId: "renamed",
          filename: "src/renamed.ts",
          previousFilename: "src/previous.ts",
          status: "renamed",
          patch: "@@ -1 +1 @@\n-old\n+new",
          additions: 1,
          deletions: 1,
          viewed: false,
        },
      ],
    };
    const validationResult =
      createDiffViewModelValidator().validate(statusSnapshot);
    if (validationResult.type === "error") {
      throw new Error(validationResult.message);
    }

    const parseResult = createDiffParser().parse(validationResult.value);
    expect(parseResult.type).toBe("success");
    if (parseResult.type === "error") {
      throw new Error(parseResult.message);
    }

    const renderResult = createDiffRenderer().createRenderPlan(
      parseResult.value,
    );
    expect(renderResult.type).toBe("success");
    if (renderResult.type === "error") {
      throw new Error(renderResult.message);
    }
    expect(readRenderPlan(renderResult.value).entries).toHaveLength(4);
    expect(
      readRenderPlan(renderResult.value).entries.map((entry) => entry.kind),
    ).toEqual(["rendered", "rendered", "rendered", "rendered"]);
  });

  test("renders an empty patch as a line-by-line entry", () => {
    const emptyPatchSnapshot: DiffSnapshot = {
      ...validSnapshot,
      files: [
        {
          ...validSnapshot.files[0],
          fileId: "empty-patch-file",
          patch: "",
          additions: 0,
          deletions: 0,
        },
      ],
    };
    const validationResult =
      createDiffViewModelValidator().validate(emptyPatchSnapshot);
    if (validationResult.type === "error") {
      throw new Error(validationResult.message);
    }

    const parseResult = createDiffParser().parse(validationResult.value);

    expect(parseResult.type).toBe("success");
    if (parseResult.type === "error") {
      throw new Error(parseResult.message);
    }

    const renderResult = createDiffRenderer().createRenderPlan(
      parseResult.value,
    );

    expect(renderResult.type).toBe("success");
    if (renderResult.type === "error") {
      throw new Error(renderResult.message);
    }
    const [entry] = readRenderPlan(renderResult.value).entries;
    expect(entry).toMatchObject({
      kind: "rendered",
      file: { fileId: "empty-patch-file" },
    });
    if (entry?.kind !== "rendered") {
      throw new Error("Expected an empty patch to be rendered.");
    }
    expect(entry.html).toContain("d2h-file-wrapper");
    expect(entry.html).toContain("d2h-file-diff");
  });

  test("delivers the renderer's plan exactly once to a non-DOM output test double", () => {
    const { output, receivedPlans } = createOutputTestDouble();
    const useCase = createDiffRenderUseCase({
      validator: createDiffViewModelValidator(),
      parser: createDiffParser(),
      renderer: createDiffRenderer(),
      output,
    });

    expect(useCase.execute(validSnapshot)).toEqual({ type: "success" });
    expect(receivedPlans).toHaveLength(1);
    expect(
      readRenderPlan(receivedPlans[0] as RenderPlan).entries.map(
        (entry) => entry.kind,
      ),
    ).toEqual(["rendered", "metadata-unavailable"]);
  });

  test("short-circuits before output when validation fails", () => {
    const { output, receivedPlans } = createOutputTestDouble();
    const useCase = createDiffRenderUseCase({
      validator: createDiffViewModelValidator(),
      parser: createDiffParser(),
      renderer: createDiffRenderer(),
      output,
    });

    expect(useCase.execute({ ...validSnapshot, pullRequestId: "" })).toEqual({
      type: "error",
      kind: "invalid-input",
      message: "Diff snapshot validation failed.",
    });
    expect(receivedPlans).toHaveLength(0);
  });

  test("short-circuits before output when parsing fails", () => {
    const { output, receivedPlans } = createOutputTestDouble();
    const useCase = createDiffRenderUseCase({
      validator: createDiffViewModelValidator(),
      parser: createDiffParser({
        parseDiff() {
          throw new Error("unavailable");
        },
      }),
      renderer: createDiffRenderer(),
      output,
    });

    expect(useCase.execute(validSnapshot)).toEqual({
      type: "error",
      kind: "parse-error",
      message: "Diff parsing failed.",
    });
    expect(receivedPlans).toHaveLength(0);
  });

  test("short-circuits before output when rendering fails", () => {
    const { output, receivedPlans } = createOutputTestDouble();
    const useCase = createDiffRenderUseCase({
      validator: createDiffViewModelValidator(),
      parser: createDiffParser(),
      renderer: createDiffRenderer({
        renderDiff() {
          throw new Error("unavailable");
        },
      }),
      output,
    });

    expect(useCase.execute(validSnapshot)).toEqual({
      type: "error",
      kind: "render-error",
      message: "Diff rendering failed.",
    });
    expect(receivedPlans).toHaveLength(0);
  });
});
