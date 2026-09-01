import type { ParsedDiffInput } from "../contracts/opaque-stage-inputs";
import type { RenderPlanResult } from "../contracts/stage-results";
import type { DiffRendererPort } from "./diff-renderer-port";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _rendererPort = Expect<
  Equal<
    DiffRendererPort["createRenderPlan"],
    (input: ParsedDiffInput) => RenderPlanResult
  >
>;
