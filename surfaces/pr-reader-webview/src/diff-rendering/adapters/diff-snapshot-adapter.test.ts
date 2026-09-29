// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { expect, test } from "bun:test";
import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import {
  createDiffSnapshotAdapter,
  type DiffSnapshotAdapter,
} from "./diff-snapshot-adapter";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _snapshotBoundary = Expect<
  Equal<
    DiffSnapshotAdapter["receiveSnapshot"],
    (snapshot: DiffSnapshot) => DiffRenderOutcome
  >
>;

const snapshot: DiffSnapshot = {
  pullRequestId: "p",
  snapshotId: "s",
  files: [],
};

test.each([
  { type: "success" },
  { type: "error", kind: "invalid-input", message: "invalid" },
  { type: "error", kind: "parse-error", message: "parse" },
  { type: "error", kind: "render-error", message: "render" },
  { type: "error", kind: "output-error", message: "output" },
] as const)(
  "returns facade outcome %j with one call",
  (outcome: DiffRenderOutcome) => {
    let calls = 0;
    const adapter = createDiffSnapshotAdapter({
      present(received) {
        expect(received).toBe(snapshot);
        calls += 1;
        return outcome;
      },
    });
    expect(adapter.receiveSnapshot(snapshot)).toBe(outcome);
    expect(calls).toBe(1);
  },
);
