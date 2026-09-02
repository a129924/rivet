import type { RenderPlan } from "../contracts/opaque-stage-inputs";
import type { OutputResult } from "../contracts/stage-results";
import type { DiffOutputPort } from "./diff-output-port";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _outputPort = Expect<
  Equal<DiffOutputPort["output"], (plan: RenderPlan) => OutputResult>
>;
