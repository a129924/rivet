import type { ViewedStateChange } from "../contracts/viewed-state-change";
import type { ViewedStateChangeAdapter } from "./viewed-state-change-adapter";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _notificationBoundary = Expect<
  Equal<
    ViewedStateChangeAdapter["sendViewedStateChange"],
    (change: ViewedStateChange) => void
  >
>;
