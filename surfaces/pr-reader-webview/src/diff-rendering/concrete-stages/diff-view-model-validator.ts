import type { DiffFileStatus } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { ValidatedDiffInput } from "../contracts/opaque-stage-inputs";
import type { ValidationResult } from "../contracts/stage-results";
import type { DiffViewModelValidatorPort } from "../ports/diff-view-model-validator-port";

export interface ValidatedDiffFile {
  readonly fileId: string;
  readonly filename: string;
  readonly previousFilename?: string;
  readonly status: DiffFileStatus;
  readonly patch?: string;
  readonly additions: number;
  readonly deletions: number;
  readonly viewed: boolean;
}

export interface ValidatedDiffInputData {
  readonly pullRequestId: string;
  readonly snapshotId: string;
  readonly files: readonly ValidatedDiffFile[];
}

const invalidInputMessage = "Diff snapshot validation failed.";

export function createDiffViewModelValidator(): DiffViewModelValidatorPort {
  return {
    validate(snapshot) {
      const validatedInput = validateSnapshot(snapshot);
      return validatedInput === undefined
        ? invalidInputResult()
        : { type: "success", value: validatedInput };
    },
  };
}

export function readValidatedDiffInput(
  input: ValidatedDiffInput,
): ValidatedDiffInputData {
  return input as unknown as ValidatedDiffInputData;
}

function validateSnapshot(
  snapshot: DiffSnapshot,
): ValidatedDiffInput | undefined {
  if (!isRecord(snapshot)) {
    return undefined;
  }

  const pullRequestId = snapshot.pullRequestId;
  const snapshotId = snapshot.snapshotId;
  const files = snapshot.files;
  if (
    !isNonEmptyString(pullRequestId) ||
    !isNonEmptyString(snapshotId) ||
    !Array.isArray(files)
  ) {
    return undefined;
  }

  const fileIds = new Set<string>();
  const validatedFiles: ValidatedDiffFile[] = [];
  for (const file of files) {
    const validatedFile = validateFile(file, fileIds);
    if (validatedFile === undefined) {
      return undefined;
    }

    fileIds.add(validatedFile.fileId);
    validatedFiles.push(validatedFile);
  }

  return Object.freeze({
    pullRequestId,
    snapshotId,
    files: Object.freeze(validatedFiles),
  }) as unknown as ValidatedDiffInput;
}

function validateFile(
  file: unknown,
  fileIds: ReadonlySet<string>,
): ValidatedDiffFile | undefined {
  if (!isRecord(file)) {
    return undefined;
  }

  const { fileId, filename, status, additions, deletions, viewed } = file;
  const patch = file.patch;
  const previousFilename = file.previousFilename;
  if (
    !isNonEmptyString(fileId) ||
    fileIds.has(fileId) ||
    !isNonEmptyString(filename) ||
    !isDiffFileStatus(status) ||
    typeof viewed !== "boolean" ||
    !isNonNegativeSafeInteger(additions) ||
    !isNonNegativeSafeInteger(deletions) ||
    (patch !== undefined && typeof patch !== "string")
  ) {
    return undefined;
  }

  let validatedPreviousFilename: string | undefined;
  if (status === "renamed") {
    if (!isNonEmptyString(previousFilename)) {
      return undefined;
    }
    validatedPreviousFilename = previousFilename;
  } else if (previousFilename !== undefined) {
    return undefined;
  }

  return Object.freeze({
    fileId,
    filename,
    ...(validatedPreviousFilename === undefined
      ? {}
      : { previousFilename: validatedPreviousFilename }),
    status,
    ...(patch === undefined ? {} : { patch }),
    additions,
    deletions,
    viewed,
  });
}

function invalidInputResult(): ValidationResult {
  return {
    type: "error",
    kind: "invalid-input",
    message: invalidInputMessage,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function isNonNegativeSafeInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value >= 0;
}

function isDiffFileStatus(value: unknown): value is DiffFileStatus {
  return (
    value === "added" ||
    value === "removed" ||
    value === "modified" ||
    value === "renamed"
  );
}
