import type {
  DiffRenderOutcome,
  DiffViewModel,
} from "../contracts/diff-view-model";
import type { ViewedStateChange } from "../contracts/viewed-state-change";
import type { ViewedStateChangePort } from "../ports/viewed-state-change-port";
import type { DiffRenderUseCase } from "../usecases/diff-render-use-case";
import type { DiffFacade, DiffFacadeDependencies } from "./diff-facade";

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
  Equal<
    DiffFacade["present"],
    (files: readonly DiffViewModel[]) => DiffRenderOutcome
  >
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
