import { html as renderDiff2Html } from "diff2html";
import type { DiffFile } from "diff2html/lib/types";
import type { RenderPlan } from "../contracts/opaque-stage-inputs";
import type { RenderPlanResult } from "../contracts/stage-results";
import type { DiffRendererPort } from "../ports/diff-renderer-port";
import { readParsedDiffInput, type ParsedDiffEntry } from "./diff-parser";
import type { ValidatedDiffFile } from "./diff-view-model-validator";

export type RenderPlanEntry =
  | {
      readonly kind: "rendered";
      readonly file: ValidatedDiffFile;
      readonly html: string;
    }
  | {
      readonly kind: "metadata-unavailable";
      readonly file: ValidatedDiffFile;
    };

export interface RenderPlanData {
  readonly entries: readonly RenderPlanEntry[];
}

export interface DiffRenderConfiguration {
  readonly outputFormat: "line-by-line";
  readonly drawFileList: false;
}

export interface DiffRendererDependencies {
  readonly renderDiff?: (
    diff: readonly DiffFile[],
    configuration: DiffRenderConfiguration,
  ) => string;
}

const renderConfiguration: DiffRenderConfiguration = Object.freeze({
  outputFormat: "line-by-line",
  drawFileList: false,
});
const renderErrorMessage = "Diff rendering failed.";

export function createDiffRenderer(
  dependencies: DiffRendererDependencies = {},
): DiffRendererPort {
  const renderDiff = dependencies.renderDiff ?? defaultRenderDiff;

  return {
    createRenderPlan(input) {
      try {
        const entries = readParsedDiffInput(input).entries.map((entry) =>
          createRenderPlanEntry(entry, renderDiff),
        );
        return {
          type: "success",
          value: Object.freeze({
            entries: Object.freeze(entries),
          }) as unknown as RenderPlan,
        };
      } catch {
        return renderErrorResult();
      }
    },
  };
}

export function readRenderPlan(plan: RenderPlan): RenderPlanData {
  return plan as unknown as RenderPlanData;
}

function createRenderPlanEntry(
  entry: ParsedDiffEntry,
  renderDiff: (
    diff: readonly DiffFile[],
    configuration: DiffRenderConfiguration,
  ) => string,
): RenderPlanEntry {
  if (entry.kind === "metadata-unavailable") {
    return Object.freeze({ kind: "metadata-unavailable", file: entry.file });
  }

  return Object.freeze({
    kind: "rendered",
    file: entry.file,
    html: renderDiff(entry.diff, renderConfiguration),
  });
}

function defaultRenderDiff(
  diff: readonly DiffFile[],
  configuration: DiffRenderConfiguration,
): string {
  return renderDiff2Html([...diff], configuration);
}

function renderErrorResult(): RenderPlanResult {
  return {
    type: "error",
    kind: "render-error",
    message: renderErrorMessage,
  };
}
