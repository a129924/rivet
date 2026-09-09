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
    sourceHunks !== undefined &&
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
  sourceHunk: UnifiedDiffHunk,
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
    !areEqualUnifiedDiffHunkTuples(sourceHunk.tuple, parsedHunk)
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
    oldLineCount === sourceHunk.tuple.old.count &&
    newLineCount === sourceHunk.tuple.new.count &&
    value.lines.length === sourceHunk.lines.length &&
    value.lines.every((line, index) =>
      isExpectedDiff2HtmlLine(line, sourceHunk.lines[index]),
    )
  );
}

function isExpectedDiff2HtmlLine(
  value: unknown,
  expectation: UnifiedDiffLineExpectation | undefined,
): boolean {
  return (
    expectation !== undefined &&
    isRecord(value) &&
    value.content === expectation.content &&
    value.type === expectation.type &&
    value.oldNumber === expectation.oldNumber &&
    value.newNumber === expectation.newNumber
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

interface UnifiedDiffHunkTuple {
  readonly old: UnifiedDiffHunkRange;
  readonly new: UnifiedDiffHunkRange;
}

interface UnifiedDiffHunk {
  readonly tuple: UnifiedDiffHunkTuple;
  readonly lines: readonly UnifiedDiffLineExpectation[];
}

interface UnifiedDiffLineExpectation {
  readonly content: string;
  readonly type: "context" | "delete" | "insert";
  readonly oldNumber: number | undefined;
  readonly newNumber: number | undefined;
}

interface UnifiedDiffHunkRange {
  readonly start: number;
  readonly count: number;
}

function readUnifiedDiffHunkTuples(
  patch: string,
): readonly UnifiedDiffHunk[] | undefined {
  const sourceLines = canonicalizeForDiff2HtmlComparison(patch).split("\n");
  if (sourceLines[sourceLines.length - 1] === "") {
    sourceLines.pop();
  }

  const hunks: UnifiedDiffHunk[] = [];
  let currentHunk: MutableUnifiedDiffHunk | undefined;
  for (const sourceLine of sourceLines) {
    const tuple = readUnifiedDiffHunkTuple(sourceLine);
    if (tuple !== undefined) {
      currentHunk = {
        tuple,
        lines: [],
        nextOldNumber: tuple.old.start,
        nextNewNumber: tuple.new.start,
      };
      hunks.push(currentHunk);
      continue;
    }

    if (currentHunk !== undefined) {
      if (isNoNewlineAtEndOfFileMarker(sourceLine)) {
        continue;
      }
      const expectation = readUnifiedDiffLineExpectation(
        sourceLine,
        currentHunk,
      );
      if (expectation === undefined) {
        return undefined;
      }
      currentHunk.lines.push(expectation);
    }
  }

  return hunks;
}

function canonicalizeForDiff2HtmlComparison(source: string): string {
  return source.replace(/\r\n/g, "\n");
}

function isNoNewlineAtEndOfFileMarker(sourceLine: string): boolean {
  return sourceLine === "\\ No newline at end of file";
}

interface MutableUnifiedDiffHunk extends UnifiedDiffHunk {
  readonly lines: UnifiedDiffLineExpectation[];
  nextOldNumber: number;
  nextNewNumber: number;
}

function readUnifiedDiffLineExpectation(
  sourceLine: string,
  hunk: MutableUnifiedDiffHunk,
): UnifiedDiffLineExpectation | undefined {
  switch (sourceLine[0]) {
    case " ": {
      const expectation = {
        content: sourceLine,
        type: "context" as const,
        oldNumber: hunk.nextOldNumber,
        newNumber: hunk.nextNewNumber,
      };
      hunk.nextOldNumber += 1;
      hunk.nextNewNumber += 1;
      return expectation;
    }
    case "-": {
      const expectation = {
        content: sourceLine,
        type: "delete" as const,
        oldNumber: hunk.nextOldNumber,
        newNumber: undefined,
      };
      hunk.nextOldNumber += 1;
      return expectation;
    }
    case "+": {
      const expectation = {
        content: sourceLine,
        type: "insert" as const,
        oldNumber: undefined,
        newNumber: hunk.nextNewNumber,
      };
      hunk.nextNewNumber += 1;
      return expectation;
    }
    default:
      return undefined;
  }
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
