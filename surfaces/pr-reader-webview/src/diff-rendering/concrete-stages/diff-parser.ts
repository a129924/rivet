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
  const source = createGitDiffTemplate(templateInput).toUnifiedDiff();
  const diff = parseDiff(source);
  if (!isCompleteDiff2HtmlParseResult(diff, source, file.patch.length === 0)) {
    throw new Error("Diff parser returned an unusable result.");
  }
  return Object.freeze({ kind: "parsed", file, diff: Object.freeze(diff) });
}

function isCompleteDiff2HtmlParseResult(
  value: unknown,
  source: string,
  isEmptyPatch: boolean,
): value is DiffFile[] {
  const sourceHunks = readUnifiedDiffHunkTuples(source);
  return (
    Array.isArray(value) &&
    value.length === 1 &&
    value.every(
      (file) =>
        isRecord(file) &&
        file.isGitDiff === true &&
        Array.isArray(file.blocks) &&
        (isEmptyPatch
          ? file.blocks.length === 0
          : sourceHunks.length > 0 &&
            file.blocks.length === sourceHunks.length &&
            file.blocks.every((block, index) =>
              isCompleteDiff2HtmlBlock(block, sourceHunks[index]),
            )),
    )
  );
}

function isCompleteDiff2HtmlBlock(
  value: unknown,
  sourceHunk: UnifiedDiffHunkTuple,
): boolean {
  if (
    !isRecord(value) ||
    typeof value.header !== "string" ||
    !Array.isArray(value.lines)
  ) {
    return false;
  }

  const parsedHunk = readUnifiedDiffHunkTuple(value.header);
  if (
    parsedHunk === undefined ||
    !areEqualUnifiedDiffHunkTuples(sourceHunk, parsedHunk)
  ) {
    return false;
  }

  let oldLineCount = 0;
  let newLineCount = 0;
  for (const line of value.lines) {
    if (!isRecord(line)) {
      return false;
    }
    if (typeof line.oldNumber === "number") {
      oldLineCount += 1;
    }
    if (typeof line.newNumber === "number") {
      newLineCount += 1;
    }
  }
  return (
    oldLineCount === sourceHunk.old.count &&
    newLineCount === sourceHunk.new.count
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

interface UnifiedDiffHunkTuple {
  readonly old: UnifiedDiffHunkRange;
  readonly new: UnifiedDiffHunkRange;
}

interface UnifiedDiffHunkRange {
  readonly start: number;
  readonly count: number;
}

function readUnifiedDiffHunkTuples(
  patch: string,
): readonly UnifiedDiffHunkTuple[] {
  return patch
    .split(/\r?\n/)
    .map((line) => readUnifiedDiffHunkTuple(line))
    .filter((hunk): hunk is UnifiedDiffHunkTuple => hunk !== undefined);
}

function readUnifiedDiffHunkTuple(
  value: string,
): UnifiedDiffHunkTuple | undefined {
  const match =
    /^@@ -(0|[1-9]\d*)(?:,(0|[1-9]\d*))? \+(0|[1-9]\d*)(?:,(0|[1-9]\d*))? @@(?:.*)$/.exec(
      value,
    );
  if (match === null) {
    return undefined;
  }

  return {
    old: {
      start: Number(match[1]),
      count: match[2] === undefined ? 1 : Number(match[2]),
    },
    new: {
      start: Number(match[3]),
      count: match[4] === undefined ? 1 : Number(match[4]),
    },
  };
}

function areEqualUnifiedDiffHunkTuples(
  source: UnifiedDiffHunkTuple,
  parsed: UnifiedDiffHunkTuple,
): boolean {
  return (
    source.old.start === parsed.old.start &&
    source.old.count === parsed.old.count &&
    source.new.start === parsed.new.start &&
    source.new.count === parsed.new.count
  );
}

function parseErrorResult(): ParseResult {
  return {
    type: "error",
    kind: "parse-error",
    message: parseErrorMessage,
  };
}
