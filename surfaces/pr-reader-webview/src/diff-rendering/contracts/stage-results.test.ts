import type {
  ParsedDiffInput,
  RenderPlan,
  ValidatedDiffInput,
} from "./opaque-stage-inputs";
import type {
  OutputResult,
  ParseResult,
  RenderPlanResult,
  ValidationResult,
} from "./stage-results";
import type { DiffOutputPort } from "../ports/diff-output-port";
import type { DiffParserPort } from "../ports/diff-parser-port";
import type { DiffRendererPort } from "../ports/diff-renderer-port";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _validation = Expect<
  Equal<
    ValidationResult,
    | { readonly type: "success"; readonly value: ValidatedDiffInput }
    | {
        readonly type: "error";
        readonly kind: "invalid-input";
        readonly message: string;
      }
  >
>;
type _parse = Expect<
  Equal<
    ParseResult,
    | { readonly type: "success"; readonly value: ParsedDiffInput }
    | {
        readonly type: "error";
        readonly kind: "parse-error";
        readonly message: string;
      }
  >
>;
type _renderPlan = Expect<
  Equal<
    RenderPlanResult,
    | { readonly type: "success"; readonly value: RenderPlan }
    | {
        readonly type: "error";
        readonly kind: "render-error";
        readonly message: string;
      }
  >
>;
type _output = Expect<
  Equal<
    OutputResult,
    | { readonly type: "success" }
    | {
        readonly type: "error";
        readonly kind: "render-error";
        readonly message: string;
      }
  >
>;
type _validationSuccessFlowsToParser = Expect<
  Equal<
    Extract<ValidationResult, { readonly type: "success" }>["value"],
    Parameters<DiffParserPort["parse"]>[0]
  >
>;
type _parseSuccessFlowsToRenderer = Expect<
  Equal<
    Extract<ParseResult, { readonly type: "success" }>["value"],
    Parameters<DiffRendererPort["createRenderPlan"]>[0]
  >
>;
type _renderPlanSuccessFlowsToOutput = Expect<
  Equal<
    Extract<RenderPlanResult, { readonly type: "success" }>["value"],
    Parameters<DiffOutputPort["output"]>[0]
  >
>;
