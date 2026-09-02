import type { DiffSnapshot } from "./diff-snapshot";
import type { DiffViewModel } from "./diff-view-model";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _diffSnapshot = Expect<
  Equal<
    DiffSnapshot,
    {
      readonly pullRequestId: string;
      readonly snapshotId: string;
      readonly files: readonly DiffViewModel[];
    }
  >
>;
