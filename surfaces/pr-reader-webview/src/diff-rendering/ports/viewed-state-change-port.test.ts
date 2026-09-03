import type { ViewedStateChange } from "../contracts/viewed-state-change";
import type { ViewedStateChangePort } from "./viewed-state-change-port";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _viewedStateChangePort = Expect<
  Equal<ViewedStateChangePort["notify"], (change: ViewedStateChange) => void>
>;
