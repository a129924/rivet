// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { expect, test } from "bun:test";
import fixture from "../../../test-fixtures/diff-bridge-contract.json" with {
  type: "json",
};
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import {
  createDiffParser,
  readParsedDiffInput,
} from "../concrete-stages/diff-parser";
import {
  createDiffViewModelValidator,
  readValidatedDiffInput,
} from "../concrete-stages/diff-view-model-validator";

const snapshot = fixture as DiffSnapshot;

test("shared Swift and TS fixture retains six statuses, order, and optional presence", () => {
  const result = createDiffViewModelValidator().validate(snapshot);
  expect(result.type).toBe("success");
  if (result.type === "error") throw new Error(result.message);
  const files = readValidatedDiffInput(result.value).files;
  expect(files.map((file) => file.status)).toEqual([
    "added",
    "removed",
    "modified",
    "renamed",
    "copied",
    "typeChanged",
  ]);
  expect(files.map((file) => file.fileId)).toEqual([
    "f:0",
    "f:1",
    "f:2",
    "f:3",
    "f:4",
    "f:5",
  ]);
  expect(files[2].previousFilename).toBe("before.swift");
  expect(files[2].patch).toBe("");
  expect("patch" in files[4]).toBe(false);
  const parsed = createDiffParser().parse(result.value);
  expect(parsed.type).toBe("success");
  if (parsed.type === "error") throw new Error(parsed.message);
  expect(
    readParsedDiffInput(parsed.value).entries.map((entry) => entry.kind),
  ).toEqual([
    "parsed",
    "parsed",
    "parsed",
    "parsed",
    "metadata-unavailable",
    "metadata-unavailable",
  ]);
});
