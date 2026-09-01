import type { ViewedStateChange } from "./viewed-state-change";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _viewedStateChange = Expect<
  Equal<
    ViewedStateChange,
    {
      readonly pullRequestId: string;
      readonly snapshotId: string;
      readonly fileId: string;
      readonly viewed: boolean;
    }
  >
>;
