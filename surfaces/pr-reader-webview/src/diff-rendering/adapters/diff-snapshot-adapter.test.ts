import type { DiffViewModel } from "../contracts/diff-view-model";
import type { DiffSnapshotAdapter } from "./diff-snapshot-adapter";

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
    (files: readonly DiffViewModel[]) => void
  >
>;
