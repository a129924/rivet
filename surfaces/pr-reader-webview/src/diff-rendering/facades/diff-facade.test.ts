// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { ViewedStateChange } from "../contracts/viewed-state-change";
import type { ViewedStateChangePort } from "../ports/viewed-state-change-port";
import type { DiffRenderUseCase } from "../usecases/diff-render-use-case";
import type { DiffFacade, DiffFacadeDependencies } from "./diff-facade";
import { createDiffFacade } from "./diff-facade";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _dependencyKeys = Expect<
  Equal<keyof DiffFacadeDependencies, "useCase" | "viewedStateChange">
>;
type _dependencies = Expect<
  Equal<
    DiffFacadeDependencies,
    {
      readonly useCase: DiffRenderUseCase;
      readonly viewedStateChange: ViewedStateChangePort;
    }
  >
>;
type _present = Expect<
  Equal<DiffFacade["present"], (snapshot: DiffSnapshot) => DiffRenderOutcome>
>;
type _viewedStateChange = Expect<
  Equal<
    DiffFacade["requestViewedStateChange"],
    (change: ViewedStateChange) => void
  >
>;
type _facadeMethods = Expect<
  Equal<keyof DiffFacade, "present" | "requestViewedStateChange">
>;

const snapshot: DiffSnapshot = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  files: [],
};
const change: ViewedStateChange = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  fileId: "file-789",
  viewed: true,
};

describe("createDiffFacade", () => {
  test("delegates present once and returns the use case outcome unchanged", () => {
    const outcome: DiffRenderOutcome = {
      type: "error",
      kind: "parse-error",
      message: "unparseable diff",
    };
    const receivedSnapshots: DiffSnapshot[] = [];
    const facade = createDiffFacade({
      useCase: {
        execute(receivedSnapshot) {
          receivedSnapshots.push(receivedSnapshot);
          return outcome;
        },
      },
      viewedStateChange: { notify: () => undefined },
    });

    expect(facade.present(snapshot)).toBe(outcome);
    expect(receivedSnapshots).toEqual([snapshot]);
  });

  test("delegates a success outcome once and returns it unchanged", () => {
    const outcome: DiffRenderOutcome = { type: "success" };
    let executeCalls = 0;
    const facade = createDiffFacade({
      useCase: {
        execute(receivedSnapshot) {
          executeCalls += 1;
          expect(receivedSnapshot).toBe(snapshot);
          return outcome;
        },
      },
      viewedStateChange: { notify: () => undefined },
    });

    expect(facade.present(snapshot)).toBe(outcome);
    expect(executeCalls).toBe(1);
  });

  test("forwards viewed changes once without invoking the use case", () => {
    const notifications: ViewedStateChange[] = [];
    let executeCalls = 0;
    const facade = createDiffFacade({
      useCase: {
        execute: () => {
          executeCalls += 1;
          return { type: "success" };
        },
      },
      viewedStateChange: {
        notify(receivedChange) {
          notifications.push(receivedChange);
        },
      },
    });

    expect(facade.requestViewedStateChange(change)).toBeUndefined();
    expect(notifications).toEqual([change]);
    expect(executeCalls).toBe(0);
  });
});
