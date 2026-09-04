import { parse as parseDiff2Html } from "diff2html";
import type { DiffFile } from "diff2html/lib/types";
import type { ParsedDiffInput } from "../contracts/opaque-stage-inputs";
import type { ParseResult } from "../contracts/stage-results";
import type { DiffParserPort } from "../ports/diff-parser-port";
import {
  createGitDiffTemplate,
  createGitDiffTemplateInput,
} from "./git-diff-template";
import {
  readValidatedDiffInput,
  type ValidatedDiffFile,
} from "./diff-view-model-validator";

export type ParsedDiffEntry =
  | {
      readonly kind: "parsed";
      readonly file: ValidatedDiffFile;
      readonly diff: readonly DiffFile[];
    }
  | {
      readonly kind: "metadata-unavailable";
      readonly file: ValidatedDiffFile;
    };

export interface ParsedDiffInputData {
  readonly entries: readonly ParsedDiffEntry[];
}

export interface DiffParserDependencies {
  readonly parseDiff?: (source: string) => DiffFile[];
}

const parseErrorMessage = "Diff parsing failed.";

export function createDiffParser(
  dependencies: DiffParserDependencies = {},
): DiffParserPort {
  const parseDiff = dependencies.parseDiff ?? parseDiff2Html;

  return {
    parse(input) {
      try {
        const files = readValidatedDiffInput(input).files;
        const entries = files.map((file) => createParsedEntry(file, parseDiff));
        return {
          type: "success",
          value: Object.freeze({
            entries: Object.freeze(entries),
          }) as unknown as ParsedDiffInput,
        };
      } catch {
        return parseErrorResult();
      }
    },
  };
}

export function readParsedDiffInput(
  input: ParsedDiffInput,
): ParsedDiffInputData {
  return input as unknown as ParsedDiffInputData;
}

function createParsedEntry(
  file: ValidatedDiffFile,
  parseDiff: (source: string) => DiffFile[],
): ParsedDiffEntry {
  if (file.patch === undefined) {
    return Object.freeze({ kind: "metadata-unavailable", file });
  }

  const templateInput = createGitDiffTemplateInput({
    fileId: file.fileId,
    filename: file.filename,
    ...(file.previousFilename === undefined
      ? {}
      : { previousFilename: file.previousFilename }),
    status: file.status,
    patch: file.patch,
  });
  const diff = parseDiff(createGitDiffTemplate(templateInput).toUnifiedDiff());
  if (!isUsableParsedDiff(diff, file.patch)) {
    throw new Error("Diff parser returned an unusable result.");
  }
  return Object.freeze({ kind: "parsed", file, diff: Object.freeze(diff) });
}

function isUsableParsedDiff(
  value: unknown,
  patch: string,
): value is DiffFile[] {
  return (
    Array.isArray(value) &&
    value.length === 1 &&
    value.every(
      (file) =>
        isRecord(file) &&
        file.isGitDiff === true &&
        Array.isArray(file.blocks) &&
        (patch.length === 0
          ? file.blocks.length === 0
          : file.blocks.length > 0 &&
            file.blocks.every(
              (block) =>
                isRecord(block) &&
                typeof block.header === "string" &&
                isUnifiedDiffHunkHeader(block.header) &&
                Array.isArray(block.lines),
            )),
    )
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isUnifiedDiffHunkHeader(value: string): boolean {
  return /^@@ -(?:0(?:,0)?|[1-9]\d*(?:,\d+)?) \+(?:0(?:,0)?|[1-9]\d*(?:,\d+)?) @@(?:.*)$/.test(
    value,
  );
}

function parseErrorResult(): ParseResult {
  return {
    type: "error",
    kind: "parse-error",
    message: parseErrorMessage,
  };
}
